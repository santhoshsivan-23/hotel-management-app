const pool = require("../config/db");
const { generateUuid } = require("../utils/uuid");

async function findAll({ status, bookingId } = {}) {
  const clauses = ["1 = 1"];
  const params = [];
  if (status) { clauses.push("sr.status = ?"); params.push(status); }
  if (bookingId) { clauses.push("sr.booking_id = ?"); params.push(bookingId); }

  const [rows] = await pool.query(
    `SELECT sr.*, r.room_number, st.name AS service_name FROM service_requests sr
     JOIN rooms r ON r.id = sr.room_id
     JOIN service_types st ON st.id = sr.service_type_id
     WHERE ${clauses.join(" AND ")}
     ORDER BY sr.created_at DESC`,
    params
  );
  return rows;
}

async function findById(id) {
  const [rows] = await pool.query("SELECT * FROM service_requests WHERE id = ? LIMIT 1", [id]);
  return rows[0] || null;
}

async function findByUuid(uuid) {
  const [rows] = await pool.query("SELECT * FROM service_requests WHERE uuid = ? LIMIT 1", [uuid]);
  return rows[0] || null;
}

async function create({ booking_id, room_id, guest_id, service_type_id, quantity, amount, notes, device_id }, conn = pool) {
  const uuid = generateUuid();
  const [result] = await conn.query(
    `INSERT INTO service_requests
      (uuid, booking_id, room_id, guest_id, service_type_id, quantity, amount, status, notes, created_by_device)
     VALUES (?, ?, ?, ?, ?, ?, ?, 'REQUESTED', ?, ?)`,
    [uuid, booking_id, room_id, guest_id, service_type_id, quantity, amount, notes || null, device_id || null]
  );
  return findById(result.insertId);
}

async function updateStatus(id, status) {
  await pool.query("UPDATE service_requests SET status = ?, updated_at = NOW() WHERE id = ?", [status, id]);
  return findById(id);
}

async function totalForBooking(bookingId) {
  const [[row]] = await pool.query(
    "SELECT COALESCE(SUM(amount), 0) AS total FROM service_requests WHERE booking_id = ? AND status != 'CANCELLED'",
    [bookingId]
  );
  return Number(row.total);
}

module.exports = { findAll, findById, findByUuid, create, updateStatus, totalForBooking };
