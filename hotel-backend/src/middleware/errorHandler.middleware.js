const logger = require("../utils/logger");

// Central error handler - every asyncHandler-wrapped controller and every
// `next(err)` call ends up here. Keep it last in the middleware chain.
function errorHandler(err, req, res, next) { // eslint-disable-line no-unused-vars
  const status = err.status || err.statusCode || 500;
  const message = err.message || "Internal server error";

  if (status >= 500) {
    logger.error(`${req.method} ${req.originalUrl} -> ${status} ${message}\n${err.stack}`);
  } else {
    logger.warn(`${req.method} ${req.originalUrl} -> ${status} ${message}`);
  }

  res.status(status).json({
    message,
    ...(process.env.NODE_ENV !== "production" && err.stack ? { stack: err.stack } : {}),
  });
}

function notFoundHandler(req, res) {
  res.status(404).json({ message: `Route not found: ${req.method} ${req.originalUrl}` });
}

module.exports = { errorHandler, notFoundHandler };
