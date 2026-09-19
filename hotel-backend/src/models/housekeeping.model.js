const pool = require("../config/db");
const { generateUuid } = require("../utils/uuid");

async function findAll({ status } = {}) {
  const clauses = ["1 = 1"];
  const params = [];
  if (status) { clauses.push("h.status = ?"); params.push(status); }

  const [rows] = await pool.query(
    `SELECT h.*, r.room_number FROM housekeeping_tasks h
     JOIN rooms r ON r.id = h.room_id
     WHERE ${clauses.join(" AND ")}
     ORDER BY h.created_at DESC`,
    params
  );
  return rows;
}

async function findByUuid(uuid) {
  const [rows] = await pool.query("SELECT * FROM housekeeping_tasks WHERE uuid = ? LIMIT 1", [uuid]);
  return rows[0] || null;
}

async function createForRoom(roomId, conn = pool) {
  const uuid = generateUuid();
  const [result] = await conn.query(
    `INSERT INTO housekeeping_tasks (uuid, room_id, status, created_at, updated_at)
     VALUES (?, 'DIRTY', NOW(), NOW())`,
    [uuid]
  );
  const [rows] = await conn.query("SELECT * FROM housekeeping_tasks WHERE id = ?", [result.insertId]);
  return rows[0];
}

async function updateStatus(id, status) {
  const startedAt = status === "CLEANING" ? "NOW()" : "started_at";
  const completedAt = status === "AVAILABLE" ? "NOW()" : "completed_at";

  await pool.query(
    `UPDATE housekeeping_tasks SET status = ?, started_at = ${startedAt},
     completed_at = ${completedAt}, updated_at = NOW() WHERE id = ?`,
    [status, id]
  );
  const [rows] = await pool.query("SELECT * FROM housekeeping_tasks WHERE id = ?", [id]);
  return rows[0];
}

module.exports = { findAll, findByUuid, createForRoom, updateStatus };
