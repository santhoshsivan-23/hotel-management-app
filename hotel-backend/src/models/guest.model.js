const pool = require("../config/db");
const { generateUuid } = require("../utils/uuid");

async function findAll({ search } = {}) {
  let sql = "SELECT * FROM guests WHERE is_deleted = 0";
  const params = [];

  if (search) {
    sql += " AND (name LIKE ? OR mobile LIKE ? OR email LIKE ?)";
    const like = `%${search}%`;
    params.push(like, like, like);
  }

  sql += " ORDER BY created_at DESC";
  const [rows] = await pool.query(sql, params);
  return rows;
}

async function findById(id) {
  const [rows] = await pool.query("SELECT * FROM guests WHERE id = ? AND is_deleted = 0 LIMIT 1", [id]);
  return rows[0] || null;
}

async function findByUuid(uuid) {
  const [rows] = await pool.query("SELECT * FROM guests WHERE uuid = ? LIMIT 1", [uuid]);
  return rows[0] || null;
}

async function create(data, conn = pool) {
  const uuid = data.uuid || generateUuid();
  const [result] = await conn.query(
    `INSERT INTO guests (uuid, name, mobile, email, id_proof_type, id_proof_number, address, created_by_device)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      uuid,
      data.name,
      data.mobile,
      data.email || null,
      data.id_proof_type || null,
      data.id_proof_number || null,
      data.address || null,
      data.device_id || null,
    ]
  );
  const [rows] = await conn.query("SELECT * FROM guests WHERE id = ?", [result.insertId]);
  return rows[0];
}

async function update(id, data) {
  const fields = ["name", "mobile", "email", "id_proof_type", "id_proof_number", "address"];
  const setCols = fields.filter((f) => data[f] !== undefined);
  if (setCols.length === 0) return findById(id);

  const setClause = setCols.map((f) => `${f} = ?`).join(", ");
  const values = setCols.map((f) => data[f]);
  values.push(id);

  await pool.query(`UPDATE guests SET ${setClause}, updated_at = NOW() WHERE id = ?`, values);
  return findById(id);
}

async function remove(id) {
  const [result] = await pool.query("UPDATE guests SET is_deleted = 1 WHERE id = ?", [id]);
  return result.affectedRows > 0;
}

async function bookingHistory(guestId) {
  const [rows] = await pool.query(
    `SELECT b.*, r.room_number FROM bookings b
     JOIN rooms r ON r.id = b.room_id
     WHERE b.guest_id = ? ORDER BY b.check_in DESC`,
    [guestId]
  );
  return rows;
}

module.exports = { findAll, findById, findByUuid, create, update, remove, bookingHistory };
