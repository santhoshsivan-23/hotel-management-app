const logger = require("../utils/logger");

// Stubs - wire up an SMS/email provider here when the business needs it.
// Kept as no-ops so the rest of the app can call them unconditionally.
async function sendBookingConfirmation(booking) {
  logger.info(`(stub) Booking confirmation for booking #${booking.booking_number} -> guest ${booking.guest_id}`);
}

async function sendInvoiceEmail(invoice, guestEmail) {
  if (!guestEmail) return;
  logger.info(`(stub) Invoice ${invoice.invoice_number} emailed to ${guestEmail}`);
}

module.exports = { sendBookingConfirmation, sendInvoiceEmail };
