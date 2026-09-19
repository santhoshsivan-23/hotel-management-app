const asyncHandler = require("../utils/asyncHandler");
const paymentModel = require("../models/payment.model");

const listByBooking = asyncHandler(async (req, res) => {
  const rows = await paymentModel.findByBooking(req.params.bookingId);
  res.json(rows);
});

const create = asyncHandler(async (req, res) => {
  const payment = await paymentModel.create(req.body);
  res.status(201).json(payment);
});

module.exports = { listByBooking, create };
