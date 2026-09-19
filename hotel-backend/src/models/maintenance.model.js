const pool = require("../config/db");
const { generateUuid } = require("../utils/uuid");

async function findAll({ status } = {}) {
  const clauses = ["1 = 1"];
  const params = [];
  if (status) { clauses.push("m.status = ?"); params.push(status); }

  const [rows] = await pool.query(
    `SELECT m.*, r.room_number FROM maintenance_requests m
     JOIN rooms r ON r.id = m.room_id
     WHERE ${clauses.join(" AND ")}
     ORDER BY m.reported_at DESC`,
    params
  );
  return rows;
}

async function findByUuid(uuid) {
  const [rows] = await pool.query("SELECT * FROM maintenance_requests WHERE uuid = ? LIMIT 1", [uuid]);
  return rows[0] || null;
}

async function create({ room_id, issue, notes, device_id }, conn = pool) {
  const uuid = generateUuid();
  const [result] = await conn.query(
    `INSERT INTO maintenance_requests (uuid, room_id, issue, status, notes, reported_at, created_by_device)
     VALUES (?, ?, ?, 'REPORTED', ?, NOW(), ?)`,
    [uuid, room_id, issue, notes || null, device_id || null]
  );
  const [rows] = await conn.query("SELECT * FROM maintenance_requests WHERE id = ?", [result.insertId]);
  return rows[0];
}

async function updateStatus(id, status, assignedTo) {
  const fixedAt = status === "FIXED" || status === "COMPLETED" ? "NOW()" : "fixed_at";
  await pool.query(
    `UPDATE maintenance_requests SET status = ?, assigned_to = COALESCE(?, assigned_to),
     fixed_at = ${fixedAt}, updated_at = NOW() WHERE id = ?`,
    [status, assignedTo || null, id]
  );
  const [rows] = await pool.query("SELECT * FROM maintenance_requests WHERE id = ?", [id]);
  return rows[0];
}

module.exports = { findAll, findByUuid, create, updateStatus };
