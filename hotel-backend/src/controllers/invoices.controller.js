const asyncHandler = require("../utils/asyncHandler");
const invoiceService = require("../services/invoice.service");
const notificationService = require("../services/notification.service");
const bookingModel = require("../models/booking.model");
const guestModel = require("../models/guest.model");

const getByBooking = asyncHandler(async (req, res) => {
  const result = await invoiceService.buildInvoice(req.params.bookingId, { persist: false });
  res.json(result);
});

const generate = asyncHandler(async (req, res) => {
  const result = await invoiceService.buildInvoice(req.params.bookingId, { persist: true });

  const booking = await bookingModel.findById(req.params.bookingId);
  const guest = await guestModel.findById(booking.guest_id);
  if (result.invoice) {
    notificationService.sendInvoiceEmail(result.invoice, guest?.email);
  }

  res.json(result);
});

module.exports = { getByBooking, generate };
