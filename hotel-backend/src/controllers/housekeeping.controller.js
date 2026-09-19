const asyncHandler = require("../utils/asyncHandler");
const housekeepingModel = require("../models/housekeeping.model");
const roomModel = require("../models/room.model");

const list = asyncHandler(async (req, res) => {
  const rows = await housekeepingModel.findAll({ status: req.query.status });
  res.json(rows);
});

const updateStatus = asyncHandler(async (req, res) => {
  const task = await housekeepingModel.updateStatus(req.params.id, req.body.status);

  if (req.body.status === "AVAILABLE") {
    await roomModel.updateStatus(task.room_id, "AVAILABLE");
  } else if (req.body.status === "CLEANING") {
    await roomModel.updateStatus(task.room_id, "CLEANING");
  }
  res.json(task);
});

module.exports = { list, updateStatus };
