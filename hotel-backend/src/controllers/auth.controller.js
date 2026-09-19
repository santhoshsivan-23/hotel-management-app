const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const asyncHandler = require("../utils/asyncHandler");
const env = require("../config/env");
const userModel = require("../models/user.model");

function signTokens(user) {
  const payload = { id: user.id, username: user.username, role: user.role, name: user.name };
  const accessToken = jwt.sign(payload, env.jwt.secret, { expiresIn: env.jwt.expiresIn });
  const refreshToken = jwt.sign({ id: user.id }, env.jwt.refreshSecret, { expiresIn: env.jwt.refreshExpiresIn });
  return { accessToken, refreshToken };
}

const login = asyncHandler(async (req, res) => {
  const { username, password } = req.body;
  const user = await userModel.findByUsername(username);

  if (!user || user.status !== "ACTIVE") {
    return res.status(401).json({ message: "Invalid username or password" });
  }

  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) {
    return res.status(401).json({ message: "Invalid username or password" });
  }

  const tokens = signTokens(user);
  res.json({
    ...tokens,
    user: { id: user.id, name: user.name, username: user.username, role: user.role },
  });
});

const refresh = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) return res.status(400).json({ message: "refreshToken is required" });

  try {
    const decoded = jwt.verify(refreshToken, env.jwt.refreshSecret);
    const user = await userModel.findById(decoded.id);
    if (!user) return res.status(401).json({ message: "Invalid refresh token" });

    const tokens = signTokens(user);
    res.json(tokens);
  } catch (err) {
    return res.status(401).json({ message: "Invalid or expired refresh token" });
  }
});

const me = asyncHandler(async (req, res) => {
  const user = await userModel.findById(req.user.id);
  if (!user) return res.status(404).json({ message: "User not found" });
  res.json(user);
});

module.exports = { login, refresh, me };
