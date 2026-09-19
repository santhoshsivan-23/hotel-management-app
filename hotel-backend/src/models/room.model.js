const pool = require("../config/db");
const { generateUuid } = require("../utils/uuid");

async function findAll({ status, roomTypeId } = {}) {
  let sql = `SELECT r.*, rt.name AS room_type_name FROM rooms r
             JOIN room_types rt ON rt.id = r.room_type_id WHERE 1 = 1`;
  const params = [];

  if (status) {
    sql += " AND r.status = ?";
    params.push(status);
  }
  if (roomTypeId) {
    sql += " AND r.room_type_id = ?";
    params.push(roomTypeId);
  }

  sql += " ORDER BY r.room_number ASC";
  const [rows] = await pool.query(sql, params);
  return rows;
}

async function findById(id) {
  const [rows] = await pool.query(
    `SELECT r.*, rt.name AS room_type_name FROM rooms r
     JOIN room_types rt ON rt.id = r.room_type_id WHERE r.id = ? LIMIT 1`,
    [id]
  );
  return rows[0] || null;
}

async function findByUuid(uuid) {
  const [rows] = await pool.query("SELECT * FROM rooms WHERE uuid = ? LIMIT 1", [uuid]);
  return rows[0] || null;
}

async function create(data) {
  const uuid = data.uuid || generateUuid();
  const [result] = await pool.query(
    `INSERT INTO rooms (uuid, room_number, room_type_id, floor, capacity, price, status)
     VALUES (?, ?, ?, ?, ?, ?, 'AVAILABLE')`,
    [uuid, data.room_number, data.room_type_id, data.floor || null, data.capacity, data.price]
  );

  if (Array.isArray(data.amenity_ids) && data.amenity_ids.length) {
    const values = data.amenity_ids.map((amenityId) => [result.insertId, amenityId]);
    await pool.query("INSERT INTO room_amenities (room_id, amenity_id) VALUES ?", [values]);
  }

  return findById(result.insertId);
}

async function update(id, data) {
  const fields = ["room_number", "room_type_id", "floor", "capacity", "price"];
  const setCols = fields.filter((f) => data[f] !== undefined);

  if (setCols.length) {
    const setClause = setCols.map((f) => `${f} = ?`).join(", ");
    const values = setCols.map((f) => data[f]);
    values.push(id);
    await pool.query(`UPDATE rooms SET ${setClause}, updated_at = NOW() WHERE id = ?`, values);
  }

  if (Array.isArray(data.amenity_ids)) {
    await pool.query("DELETE FROM room_amenities WHERE room_id = ?", [id]);
    if (data.amenity_ids.length) {
      const values = data.amenity_ids.map((amenityId) => [id, amenityId]);
      await pool.query("INSERT INTO room_amenities (room_id, amenity_id) VALUES ?", [values]);
    }
  }

  return findById(id);
}

async function updateStatus(id, status) {
  await pool.query("UPDATE rooms SET status = ?, updated_at = NOW() WHERE id = ?", [status, id]);
  return findById(id);
}

async function remove(id) {
  const [result] = await pool.query("DELETE FROM rooms WHERE id = ?", [id]);
  return result.affectedRows > 0;
}

/**
 * Core availability query (see booking.service.js for the full rule):
 * a room is available for [checkIn, checkOut) if it isn't under
 * MAINTENANCE/OUT_OF_SERVICE and has no CONFIRMED/CHECKED_IN booking whose
 * date range overlaps the requested range.
 */
async function findAvailable({ checkIn, checkOut, capacity, roomTypeId, excludeBookingId }) {
  // Overlap rule: existing.check_in < new.check_out AND existing.check_out > new.check_in
  const params = [checkOut, checkIn];

  let sql = `
    SELECT r.*, rt.name AS room_type_name
    FROM rooms r
    JOIN room_types rt ON rt.id = r.room_type_id
    WHERE r.status NOT IN ('MAINTENANCE', 'OUT_OF_SERVICE')
      AND r.id NOT IN (
        SELECT b.room_id FROM bookings b
        WHERE b.status IN ('PENDING', 'CONFIRMED', 'CHECKED_IN')
          AND b.check_in < ?
          AND b.check_out > ?
  `;

  if (excludeBookingId) {
    sql += " AND b.id != ?";
    params.push(excludeBookingId);
  }
  sql += ")";

  if (capacity) {
    sql += " AND r.capacity >= ?";
    params.push(capacity);
  }
  if (roomTypeId) {
    sql += " AND r.room_type_id = ?";
    params.push(roomTypeId);
  }

  sql += " ORDER BY r.price ASC";

  const [rows] = await pool.query(sql, params);
  return rows;
}

module.exports = { findAll, findById, findByUuid, create, update, updateStatus, remove, findAvailable };
