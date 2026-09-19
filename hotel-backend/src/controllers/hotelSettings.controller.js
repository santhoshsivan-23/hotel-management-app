const asyncHandler = require("../utils/asyncHandler");
const hotelSettingsModel = require("../models/hotelSettings.model");

const get = asyncHandler(async (req, res) => {
  const settings = await hotelSettingsModel.get();
  res.json(settings);
});

const update = asyncHandler(async (req, res) => {
  const settings = await hotelSettingsModel.update(req.body);
  res.json(settings);
});

module.exports = { get, update };
