const asyncHandler = require("../utils/asyncHandler");
const foodOrderModel = require("../models/foodOrder.model");

const pool = require("../config/db");
const bookingModel = require("../models/booking.model");

const list = asyncHandler(async (req, res) => {
  const rows = await foodOrderModel.findAll({ status: req.query.status, bookingId: req.query.booking_id });
  res.json(rows);
});

const getById = asyncHandler(async (req, res) => {
  const order = await foodOrderModel.findById(req.params.id);
  if (!order) return res.status(404).json({ message: "Food order not found" });
  res.json(order);
});

const create = asyncHandler(async (req, res) => {
  if (req.body.booking_id) {
    const booking = await bookingModel.findById(req.body.booking_id);
    if (booking && booking.status === "CHECKED_OUT") {
      return res.status(409).json({ message: "Cannot add food orders to a checked-out stay" });
    }
  }
  const order = await foodOrderModel.create(req.body);
  res.status(201).json(order);
});

const updateStatus = asyncHandler(async (req, res) => {
  const order = await foodOrderModel.updateStatus(req.params.id, req.body.status);
  res.json(order);
});

module.exports = { list, getById, create, updateStatus };
