const asyncHandler = require("../utils/asyncHandler");
const roomModel = require("../models/room.model");

const list = asyncHandler(async (req, res) => {
  const rows = await roomModel.findAll({ status: req.query.status, roomTypeId: req.query.room_type_id });
  res.json(rows);
});

const getById = asyncHandler(async (req, res) => {
  const room = await roomModel.findById(req.params.id);
  if (!room) return res.status(404).json({ message: "Room not found" });
  res.json(room);
});

const create = asyncHandler(async (req, res) => {
  const room = await roomModel.create(req.body);
  res.status(201).json(room);
});

const update = asyncHandler(async (req, res) => {
  const room = await roomModel.update(req.params.id, req.body);
  if (!room) return res.status(404).json({ message: "Room not found" });
  res.json(room);
});

const updateStatus = asyncHandler(async (req, res) => {
  const room = await roomModel.updateStatus(req.params.id, req.body.status);
  res.json(room);
});

const remove = asyncHandler(async (req, res) => {
  const ok = await roomModel.remove(req.params.id);
  if (!ok) return res.status(404).json({ message: "Room not found" });
  res.status(204).send();
});

// GET /api/rooms/available?check_in=...&check_out=...&capacity=...&room_type_id=...
const available = asyncHandler(async (req, res) => {
  const { check_in, check_out, capacity, room_type_id } = req.query;
  if (!check_in || !check_out) {
    return res.status(400).json({ message: "check_in and check_out are required" });
  }
  const rooms = await roomModel.findAvailable({
    checkIn: check_in,
    checkOut: check_out,
    capacity: capacity ? Number(capacity) : undefined,
    roomTypeId: room_type_id ? Number(room_type_id) : undefined,
  });
  res.json(rooms);
});

module.exports = { list, getById, create, update, updateStatus, remove, available };
