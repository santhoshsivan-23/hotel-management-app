const asyncHandler = require("../utils/asyncHandler");
const paymentModel = require("../models/payment.model");

const pool = require("../config/db");
const bookingModel = require("../models/booking.model");

const listByBooking = asyncHandler(async (req, res) => {
  const rows = await paymentModel.findByBooking(req.params.bookingId);
  res.json(rows);
});

const create = asyncHandler(async (req, res) => {
  if (req.body.booking_id) {
    const booking = await bookingModel.findById(req.body.booking_id);
    if (booking && booking.status === "CHECKED_OUT") {
      return res.status(409).json({ message: "Cannot add payments to a checked-out stay" });
    }
  }
  const payment = await paymentModel.create(req.body);
  res.status(201).json(payment);
});

module.exports = { listByBooking, create };
