const bookingModel = require("../models/booking.model");
const paymentModel = require("../models/payment.model");
const foodOrderModel = require("../models/foodOrder.model");
const serviceRequestModel = require("../models/serviceRequest.model");
const invoiceModel = require("../models/invoice.model");
const { generateInvoiceNumber } = require("../utils/invoiceNumberGenerator");
const { round2 } = require("../utils/currency");

/**
 * Aggregates room charges + food + services + tax - payments into the
 * running bill / final invoice, exactly per the "Running Bill" spec:
 * every charge is looked up by booking_id so nothing can be missed.
 */
async function buildInvoice(bookingId, { persist = false } = {}) {
  const booking = await bookingModel.findById(bookingId);
  if (!booking) {
    const err = new Error("Booking not found");
    err.status = 404;
    throw err;
  }

  const foodCharges = await foodOrderModel.totalForBooking(bookingId);
  const serviceCharges = await serviceRequestModel.totalForBooking(bookingId);
  const otherCharges = 0; // reserved for ad-hoc charges if introduced later
  const paidAmount = await paymentModel.totalPaid(bookingId);

  const subtotal = round2(
    Number(booking.room_total) + foodCharges + serviceCharges + otherCharges - Number(booking.discount)
  );
  const tax = Number(booking.tax_amount); // room tax already computed at booking time
  const grandTotal = round2(subtotal + tax);
  const balance = round2(grandTotal - paidAmount);

  const totals = {
    roomCharges: Number(booking.room_total),
    foodCharges,
    serviceCharges,
    otherCharges,
    discount: Number(booking.discount),
    tax,
    grandTotal,
    paidAmount,
    balance,
  };

  if (!persist) {
    return { booking, ...totals };
  }

  const invoiceNumber = await generateInvoiceNumber();
  const invoice = await invoiceModel.upsertForBooking(bookingId, totals, invoiceNumber);
  return { booking, invoice, ...totals };
}

module.exports = { buildInvoice };
