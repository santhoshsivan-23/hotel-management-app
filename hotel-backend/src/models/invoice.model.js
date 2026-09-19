const pool = require("../config/db");
const { generateUuid } = require("../utils/uuid");

async function findByBookingId(bookingId) {
  const [rows] = await pool.query("SELECT * FROM invoices WHERE booking_id = ? LIMIT 1", [bookingId]);
  return rows[0] || null;
}

async function upsertForBooking(bookingId, totals, invoiceNumber) {
  const existing = await findByBookingId(bookingId);

  if (existing) {
    await pool.query(
      `UPDATE invoices SET
         room_charges = ?, food_charges = ?, service_charges = ?, other_charges = ?,
         discount = ?, tax = ?, grand_total = ?, paid_amount = ?, balance = ?,
         generated_at = NOW()
       WHERE booking_id = ?`,
      [
        totals.roomCharges, totals.foodCharges, totals.serviceCharges, totals.otherCharges,
        totals.discount, totals.tax, totals.grandTotal, totals.paidAmount, totals.balance,
        bookingId,
      ]
    );
    return findByBookingId(bookingId);
  }

  const uuid = generateUuid();
  await pool.query(
    `INSERT INTO invoices
      (uuid, booking_id, invoice_number, room_charges, food_charges, service_charges,
       other_charges, discount, tax, grand_total, paid_amount, balance, generated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
    [
      uuid, bookingId, invoiceNumber, totals.roomCharges, totals.foodCharges,
      totals.serviceCharges, totals.otherCharges, totals.discount, totals.tax,
      totals.grandTotal, totals.paidAmount, totals.balance,
    ]
  );
  return findByBookingId(bookingId);
}

module.exports = { findByBookingId, upsertForBooking };
