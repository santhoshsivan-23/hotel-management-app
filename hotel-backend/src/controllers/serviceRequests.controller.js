const asyncHandler = require("../utils/asyncHandler");
const pool = require("../config/db");
const serviceRequestModel = require("../models/serviceRequest.model");

const list = asyncHandler(async (req, res) => {
  const rows = await serviceRequestModel.findAll({ status: req.query.status, bookingId: req.query.booking_id });
  res.json(rows);
});

const create = asyncHandler(async (req, res) => {
  const [[serviceType]] = await pool.query("SELECT price FROM service_types WHERE id = ?", [req.body.service_type_id]);
  if (!serviceType) return res.status(404).json({ message: "Service type not found" });

  const amount = Number(serviceType.price) * (req.body.quantity || 1);
  const request = await serviceRequestModel.create({ ...req.body, amount });
  res.status(201).json(request);
});

const updateStatus = asyncHandler(async (req, res) => {
  const request = await serviceRequestModel.updateStatus(req.params.id, req.body.status);
  res.json(request);
});

module.exports = { list, create, updateStatus };
