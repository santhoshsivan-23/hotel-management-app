const pool = require("../config/db");

async function nextNumber(table, prefixSettingColumn, fallbackPrefix) {
  const [[settings]] = await pool.query(
    `SELECT ${prefixSettingColumn} AS prefix FROM hotel_settings LIMIT 1`
  );
  const prefix = (settings && settings.prefix) || fallbackPrefix;

  const [[row]] = await pool.query(`SELECT COUNT(*) AS count FROM ${table}`);
  const nextSeq = (row.count || 0) + 1;
  const padded = String(nextSeq).padStart(6, "0");
  return `${prefix}-${padded}`;
}

async function generateBookingNumber() {
  return nextNumber("bookings", "booking_prefix", "BK");
}

async function generateInvoiceNumber() {
  return nextNumber("invoices", "invoice_prefix", "INV");
}

module.exports = { generateBookingNumber, generateInvoiceNumber };
