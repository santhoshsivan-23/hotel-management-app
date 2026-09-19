const pool = require("../config/db");

async function findAll() {
  const [rows] = await pool.query("SELECT * FROM roles ORDER BY name ASC");
  return rows;
}

async function findByName(name) {
  const [rows] = await pool.query("SELECT * FROM roles WHERE name = ? LIMIT 1", [name]);
  return rows[0] || null;
}

module.exports = { findAll, findByName };
