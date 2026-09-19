const pool = require("../config/db");
const { generateUuid } = require("../utils/uuid");

async function findAll({ status, bookingId } = {}) {
  const clauses = ["1 = 1"];
  const params = [];
  if (status) { clauses.push("fo.status = ?"); params.push(status); }
  if (bookingId) { clauses.push("fo.booking_id = ?"); params.push(bookingId); }

  const [rows] = await pool.query(
    `SELECT fo.*, r.room_number FROM food_orders fo
     JOIN rooms r ON r.id = fo.room_id
     WHERE ${clauses.join(" AND ")}
     ORDER BY fo.created_at DESC`,
    params
  );
  return rows;
}

async function findById(id) {
  const [[order]] = await pool.query("SELECT * FROM food_orders WHERE id = ?", [id]);
  if (!order) return null;
  const [items] = await pool.query("SELECT * FROM food_order_items WHERE food_order_id = ?", [id]);
  return { ...order, items };
}

async function findByUuid(uuid) {
  const [rows] = await pool.query("SELECT * FROM food_orders WHERE uuid = ? LIMIT 1", [uuid]);
  return rows[0] || null;
}

async function create({ booking_id, room_id, guest_id, items, device_id }, conn = pool) {
  const uuid = generateUuid();
  const totalAmount = items.reduce((sum, i) => sum + i.quantity * i.price, 0);

  const [result] = await conn.query(
    `INSERT INTO food_orders (uuid, booking_id, room_id, guest_id, status, total_amount, created_by_device)
     VALUES (?, ?, ?, ?, 'NEW', ?, ?)`,
    [uuid, booking_id, room_id, guest_id, totalAmount, device_id || null]
  );

  const foodOrderId = result.insertId;
  const itemRows = items.map((i) => [
    generateUuid(), foodOrderId, i.product_name, i.quantity, i.price, i.modifiers || null, i.notes || null,
  ]);
  await conn.query(
    `INSERT INTO food_order_items (uuid, food_order_id, product_name, quantity, price, modifiers, notes)
     VALUES ?`,
    [itemRows]
  );

  return findById(foodOrderId);
}

async function updateStatus(id, status) {
  await pool.query("UPDATE food_orders SET status = ?, updated_at = NOW() WHERE id = ?", [status, id]);
  return findById(id);
}

async function totalForBooking(bookingId) {
  const [[row]] = await pool.query(
    "SELECT COALESCE(SUM(total_amount), 0) AS total FROM food_orders WHERE booking_id = ? AND status != 'CANCELLED'",
    [bookingId]
  );
  return Number(row.total);
}

module.exports = { findAll, findById, findByUuid, create, updateStatus, totalForBooking };
