const pool = require("../config/db");

async function get() {
  const [rows] = await pool.query("SELECT * FROM hotel_settings LIMIT 1");
  return rows[0] || null;
}

async function update(data) {
  const fields = [
    "hotel_name", "logo", "address", "phone", "email", "tax_info", "currency",
    "timezone", "checkin_time", "checkout_time", "invoice_prefix", "booking_prefix",
  ];
  const setCols = fields.filter((f) => data[f] !== undefined);
  if (setCols.length === 0) return get();

  const setClause = setCols.map((f) => `${f} = ?`).join(", ");
  const values = setCols.map((f) => data[f]);

  const existing = await get();
  if (existing) {
    await pool.query(`UPDATE hotel_settings SET ${setClause} WHERE id = ?`, [...values, existing.id]);
  } else {
    const columns = setCols.join(", ");
    const placeholders = setCols.map(() => "?").join(", ");
    await pool.query(`INSERT INTO hotel_settings (${columns}) VALUES (${placeholders})`, values);
  }
  return get();
}

module.exports = { get, update };
