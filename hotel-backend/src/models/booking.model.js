const pool = require("../config/db");
const { generateUuid } = require("../utils/uuid");

const BASE_SELECT = `
  SELECT b.*, g.name AS guest_name, g.mobile AS guest_mobile,
         r.room_number, rt.name AS room_type_name
  FROM bookings b
  JOIN guests g ON g.id = b.guest_id
  JOIN rooms r ON r.id = b.room_id
  JOIN room_types rt ON rt.id = r.room_type_id
`;

async function findAll(filters = {}) {
  const clauses = ["1 = 1"];
  const params = [];

  if (filters.status) {
    clauses.push("b.status = ?");
    params.push(filters.status);
  }
  if (filters.roomId) {
    clauses.push("b.room_id = ?");
    params.push(filters.roomId);
  }
  if (filters.guestId) {
    clauses.push("b.guest_id = ?");
    params.push(filters.guestId);
  }
  if (filters.fromDate) {
    clauses.push("b.check_in >= ?");
    params.push(filters.fromDate);
  }
  if (filters.toDate) {
    clauses.push("b.check_out <= ?");
    params.push(filters.toDate);
  }

  const sql = `${BASE_SELECT} WHERE ${clauses.join(" AND ")} ORDER BY b.check_in DESC`;
  const [rows] = await pool.query(sql, params);
  return rows;
}

async function findById(id) {
  const [rows] = await pool.query(`${BASE_SELECT} WHERE b.id = ? LIMIT 1`, [id]);
  return rows[0] || null;
}

async function findByUuid(uuid) {
  const [rows] = await pool.query(`${BASE_SELECT} WHERE b.uuid = ? LIMIT 1`, [uuid]);
  return rows[0] || null;
}

/**
 * Overlap check used both by the availability search (room.model.js) and
 * here again as a final server-side guard right before insert - this is
 * what stops a double-booking even if it arrives through offline sync
 * with a stale view of the room's calendar.
 */
async function hasOverlap({ roomId, checkIn, checkOut, excludeBookingId }) {
  const params = [roomId, checkOut, checkIn];
  let sql = `
    SELECT id FROM bookings
    WHERE room_id = ?
      AND status IN ('PENDING', 'CONFIRMED', 'CHECKED_IN')
      AND check_in < ?
      AND check_out > ?
  `;
  if (excludeBookingId) {
    sql += " AND id != ?";
    params.push(excludeBookingId);
  }
  sql += " LIMIT 1";

  const [rows] = await pool.query(sql, params);
  return rows.length > 0;
}

async function create(data, conn = pool) {
  const uuid = data.uuid || generateUuid();
  const [result] = await conn.query(
    `INSERT INTO bookings
      (uuid, booking_number, guest_id, room_id, check_in, check_out, adults, children,
       room_rate, nights, room_total, discount, tax_amount, grand_total, advance_paid,
       status, created_by_device)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      uuid,
      data.booking_number,
      data.guest_id,
      data.room_id,
      data.check_in,
      data.check_out,
      data.adults,
      data.children,
      data.room_rate,
      data.nights,
      data.room_total,
      data.discount,
      data.tax_amount,
      data.grand_total,
      data.advance_paid,
      data.status,
      data.device_id || null,
    ]
  );
  return findByIdWithConn(result.insertId, conn);
}

async function findByIdWithConn(id, conn) {
  const [rows] = await conn.query(`${BASE_SELECT} WHERE b.id = ? LIMIT 1`, [id]);
  return rows[0] || null;
}

async function updateStatus(id, status) {
  await pool.query("UPDATE bookings SET status = ?, updated_at = NOW() WHERE id = ?", [status, id]);
  return findById(id);
}

async function updateRoom(id, roomId) {
  await pool.query("UPDATE bookings SET room_id = ?, updated_at = NOW() WHERE id = ?", [roomId, id]);
  return findById(id);
}

async function extendStay(id, checkOut, nights, roomTotal, grandTotal) {
  await pool.query(
    `UPDATE bookings
     SET check_out = ?, nights = ?, room_total = ?, grand_total = ?, updated_at = NOW()
     WHERE id = ?`,
    [checkOut, nights, roomTotal, grandTotal, id]
  );
  return findById(id);
}

async function addAdvancePaid(id, amount) {
  await pool.query(
    "UPDATE bookings SET advance_paid = advance_paid + ?, updated_at = NOW() WHERE id = ?",
    [amount, id]
  );
  return findById(id);
}

module.exports = {
  findAll,
  findById,
  findByUuid,
  hasOverlap,
  create,
  updateStatus,
  updateRoom,
  extendStay,
  addAdvancePaid,
};
