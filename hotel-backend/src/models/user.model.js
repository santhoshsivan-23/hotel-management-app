const pool = require("../config/db");
const { generateUuid } = require("../utils/uuid");

async function findAll() {
  const [rows] = await pool.query(
    `SELECT u.id, u.uuid, u.name, u.mobile, u.email, u.username, u.status, r.name AS role
     FROM users u JOIN roles r ON r.id = u.role_id ORDER BY u.name ASC`
  );
  return rows;
}

async function findByUsername(username) {
  const [rows] = await pool.query(
    `SELECT u.*, r.name AS role FROM users u JOIN roles r ON r.id = u.role_id
     WHERE u.username = ? LIMIT 1`,
    [username]
  );
  return rows[0] || null;
}

async function findById(id) {
  const [rows] = await pool.query(
    `SELECT u.id, u.uuid, u.name, u.mobile, u.email, u.username, u.status, r.name AS role
     FROM users u JOIN roles r ON r.id = u.role_id WHERE u.id = ? LIMIT 1`,
    [id]
  );
  return rows[0] || null;
}

async function create({ name, mobile, email, username, password_hash, role_id }) {
  const uuid = generateUuid();
  const [result] = await pool.query(
    `INSERT INTO users (uuid, name, mobile, email, username, password_hash, role_id, status)
     VALUES (?, ?, ?, ?, ?, ?, ?, 'ACTIVE')`,
    [uuid, name, mobile, email || null, username, password_hash, role_id]
  );
  return findById(result.insertId);
}

async function updateStatus(id, status) {
  await pool.query("UPDATE users SET status = ? WHERE id = ?", [status, id]);
  return findById(id);
}

module.exports = { findAll, findByUsername, findById, create, updateStatus };
