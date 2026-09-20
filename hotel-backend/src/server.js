const env = require("./config/env");
const logger = require("./utils/logger");
const { initDb } = require("./db/initDb");

let server;

async function startServer() {
  try {
    // 1. Ensure database, tables, and default seed data are created
    await initDb();

    // 2. Load Express app after the database is ready
    const app = require("./app");

    // 3. Start listening for incoming requests
    server = app.listen(env.port, () => {
      logger.info(`Hotel backend listening on port ${env.port} (${env.nodeEnv})`);
    });

    process.on("unhandledRejection", (reason) => {
      logger.error(`Unhandled promise rejection: ${reason}`);
    });

    process.on("SIGTERM", () => {
      logger.info("SIGTERM received, shutting down gracefully");
      if (server) {
        server.close(() => process.exit(0));
      } else {
        process.exit(0);
      }
    });

    return server;
  } catch (err) {
    logger.error(`Failed to start server: ${err.message}`);
    process.exit(1);
  }
}

const serverPromise = startServer();

module.exports = serverPromise;

