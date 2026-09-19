const pool = require("../config/db");
const { generateUuid } = require("../utils/uuid");

/**
 * Factory for simple reference-data tables (room_types, amenities,
 * service_types, taxes, payment_methods, ...) that all follow the same
 * shape: id, uuid, a handful of columns, active, timestamps.
 *
 * table         - MySQL table name
 * fields        - column names accepted on create/update (excludes id/uuid/timestamps)
 * defaultOrder  - ORDER BY clause fragment, e.g. "name ASC"
 */
function createCrudModel(table, fields, defaultOrder = "id ASC") {
  return {
    async findAll({ activeOnly = false } = {}) {
      const where = activeOnly ? "WHERE active = 1" : "";
      const [rows] = await pool.query(`SELECT * FROM ${table} ${where} ORDER BY ${defaultOrder}`);
      return rows;
    },

    async findById(id) {
      const [rows] = await pool.query(`SELECT * FROM ${table} WHERE id = ? LIMIT 1`, [id]);
      return rows[0] || null;
    },

    async findByUuid(uuid) {
      const [rows] = await pool.query(`SELECT * FROM ${table} WHERE uuid = ? LIMIT 1`, [uuid]);
      return rows[0] || null;
    },

    async create(data) {
      const uuid = data.uuid || generateUuid();
      const columns = ["uuid", ...fields];
      const values = [uuid, ...fields.map((f) => data[f] ?? null)];
      const placeholders = columns.map(() => "?").join(", ");

      const [result] = await pool.query(
        `INSERT INTO ${table} (${columns.join(", ")}) VALUES (${placeholders})`,
        values
      );
      return this.findById(result.insertId);
    },

    async update(id, data) {
      const setCols = fields.filter((f) => data[f] !== undefined);
      if (setCols.length === 0) return this.findById(id);

      const setClause = setCols.map((f) => `${f} = ?`).join(", ");
      const values = setCols.map((f) => data[f]);
      values.push(id);

      await pool.query(`UPDATE ${table} SET ${setClause}, updated_at = NOW() WHERE id = ?`, values);
      return this.findById(id);
    },

    async remove(id) {
      const [result] = await pool.query(`DELETE FROM ${table} WHERE id = ?`, [id]);
      return result.affectedRows > 0;
    },
  };
}

module.exports = createCrudModel;
