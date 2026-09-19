const pool = require("../config/db");
const { generateUuid } = require("../utils/uuid");

async function findByBooking(bookingId) {
  const [rows] = await pool.query(
    "SELECT * FROM payments WHERE booking_id = ? ORDER BY paid_at DESC",
    [bookingId]
  );
  return rows;
}

async function findByUuid(uuid) {
  const [rows] = await pool.query("SELECT * FROM payments WHERE uuid = ? LIMIT 1", [uuid]);
  return rows[0] || null;
}

async function totalPaid(bookingId) {
  const [[row]] = await pool.query(
    "SELECT COALESCE(SUM(amount), 0) AS total FROM payments WHERE booking_id = ?",
    [bookingId]
  );
  return Number(row.total);
}

async function create(data, conn = pool) {
  const uuid = data.uuid || generateUuid();
  const [result] = await conn.query(
    `INSERT INTO payments (uuid, booking_id, amount, method, reference_no, paid_at, created_by_device)
     VALUES (?, ?, ?, ?, ?, NOW(), ?)`,
    [uuid, data.booking_id, data.amount, data.method, data.reference_no || null, data.device_id || null]
  );
  const [rows] = await conn.query("SELECT * FROM payments WHERE id = ?", [result.insertId]);
  return rows[0];
}

module.exports = { findByBooking, findByUuid, totalPaid, create };
