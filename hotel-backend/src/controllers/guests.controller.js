const asyncHandler = require("../utils/asyncHandler");
const guestModel = require("../models/guest.model");

const list = asyncHandler(async (req, res) => {
  const rows = await guestModel.findAll({ search: req.query.search });
  res.json(rows);
});

const getById = asyncHandler(async (req, res) => {
  const guest = await guestModel.findById(req.params.id);
  if (!guest) return res.status(404).json({ message: "Guest not found" });
  const history = await guestModel.bookingHistory(guest.id);
  res.json({ ...guest, bookingHistory: history });
});

const create = asyncHandler(async (req, res) => {
  const guest = await guestModel.create(req.body);
  res.status(201).json(guest);
});

const update = asyncHandler(async (req, res) => {
  const guest = await guestModel.update(req.params.id, req.body);
  if (!guest) return res.status(404).json({ message: "Guest not found" });
  res.json(guest);
});

const remove = asyncHandler(async (req, res) => {
  const ok = await guestModel.remove(req.params.id);
  if (!ok) return res.status(404).json({ message: "Guest not found" });
  res.status(204).send();
});

module.exports = { list, getById, create, update, remove };
