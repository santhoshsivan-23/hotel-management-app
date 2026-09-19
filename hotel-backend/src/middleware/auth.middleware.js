const jwt = require("jsonwebtoken");
const env = require("../config/env");

/**
 * Verifies the Bearer JWT on every protected route and attaches the
 * decoded payload to req.user = { id, username, role, deviceId }.
 */
function authenticate(req, res, next) {
  const header = req.headers.authorization || "";
  const [scheme, token] = header.split(" ");

  if (scheme !== "Bearer" || !token) {
    return res.status(401).json({ message: "Missing or malformed Authorization header" });
  }

  try {
    const payload = jwt.verify(token, env.jwt.secret);
    req.user = payload;
    next();
  } catch (err) {
    return res.status(401).json({ message: "Invalid or expired token" });
  }
}

module.exports = authenticate;
