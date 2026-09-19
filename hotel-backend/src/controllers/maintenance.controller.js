const asyncHandler = require("../utils/asyncHandler");
const maintenanceModel = require("../models/maintenance.model");
const roomModel = require("../models/room.model");

const list = asyncHandler(async (req, res) => {
  const rows = await maintenanceModel.findAll({ status: req.query.status });
  res.json(rows);
});

const create = asyncHandler(async (req, res) => {
  const request = await maintenanceModel.create(req.body);
  await roomModel.updateStatus(req.body.room_id, "MAINTENANCE");
  res.status(201).json(request);
});

const updateStatus = asyncHandler(async (req, res) => {
  const request = await maintenanceModel.updateStatus(req.params.id, req.body.status, req.body.assigned_to);

  if (req.body.status === "COMPLETED") {
    await roomModel.updateStatus(request.room_id, "AVAILABLE");
  }
  res.json(request);
});

module.exports = { list, create, updateStatus };
