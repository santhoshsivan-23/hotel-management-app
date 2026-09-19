const asyncHandler = require("../utils/asyncHandler");
const roleModel = require("../models/role.model");

const list = asyncHandler(async (req, res) => {
  res.json(await roleModel.findAll());
});

module.exports = { list };
