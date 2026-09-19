const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const env = require("./config/env");
const requestLogger = require("./middleware/requestLogger.middleware");
const { errorHandler, notFoundHandler } = require("./middleware/errorHandler.middleware");
const apiRoutes = require("./routes");

const app = express();

app.use(helmet());
app.use(cors({ origin: env.corsOrigin === "*" ? true : env.corsOrigin.split(",") }));
app.use(express.json({ limit: "2mb" }));
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);

// Lightweight endpoint the Flutter app pings to confirm *real* internet
// reachability before it shows the "Sync Now" control (a Wi-Fi network
// with no internet still reports "connected").
app.get("/health", (req, res) => {
  res.json({ status: "ok", time: new Date().toISOString() });
});

app.use("/api", apiRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
