const bcrypt = require("bcryptjs");
const asyncHandler = require("../utils/asyncHandler");
const userModel = require("../models/user.model");
const roleModel = require("../models/role.model");

const list = asyncHandler(async (req, res) => {
  res.json(await userModel.findAll());
});

const create = asyncHandler(async (req, res) => {
  const role = await roleModel.findByName(req.body.role);
  if (!role) return res.status(400).json({ message: `Unknown role: ${req.body.role}` });

  const passwordHash = await bcrypt.hash(req.body.password, 10);
  const user = await userModel.create({
    name: req.body.name,
    mobile: req.body.mobile,
    email: req.body.email,
    username: req.body.username,
    password_hash: passwordHash,
    role_id: role.id,
  });
  res.status(201).json(user);
});

const updateStatus = asyncHandler(async (req, res) => {
  const user = await userModel.updateStatus(req.params.id, req.body.status);
  res.json(user);
});

module.exports = { list, create, updateStatus };
