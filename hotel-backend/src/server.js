const app = require("./app");
const env = require("./config/env");
const logger = require("./utils/logger");

const server = app.listen(env.port, () => {
  logger.info(`Hotel backend listening on port ${env.port} (${env.nodeEnv})`);
});

process.on("unhandledRejection", (reason) => {
  logger.error(`Unhandled promise rejection: ${reason}`);
});

process.on("SIGTERM", () => {
  logger.info("SIGTERM received, shutting down gracefully");
  server.close(() => process.exit(0));
});

module.exports = server;
