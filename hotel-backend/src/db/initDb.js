const fs = require("fs");
const path = require("path");
const mysql = require("mysql2/promise");
const env = require("../config/env");
const logger = require("../utils/logger");

/**
 * Creates the database if it doesn't already exist.
 */
async function createDatabaseIfNotExists() {
  const connection = await mysql.createConnection({
    host: env.db.host,
    port: env.db.port,
    user: env.db.user,
    password: env.db.password,
    multipleStatements: true,
  });

  try {
    await connection.query(
      `CREATE DATABASE IF NOT EXISTS \`${env.db.name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
    );
    logger.info(`Database "${env.db.name}" ensured.`);
  } finally {
    await connection.end();
  }
}

/**
 * Runs all migration SQL files in alphanumeric order against the database.
 */
async function runMigrations() {
  const connection = await mysql.createConnection({
    host: env.db.host,
    port: env.db.port,
    user: env.db.user,
    password: env.db.password,
    database: env.db.name,
    multipleStatements: true,
  });

  try {
    const dir = path.join(__dirname, "migrations");
    if (!fs.existsSync(dir)) {
      logger.warn(`Migrations directory not found at: ${dir}`);
      return;
    }

    const files = fs.readdirSync(dir).filter((f) => f.endsWith(".sql")).sort();
    logger.info(`Checking/applying ${files.length} migrations...`);

    for (const file of files) {
      const sql = fs.readFileSync(path.join(dir, file), "utf8");
      await connection.query(sql);
    }

    logger.info(`All ${files.length} migrations verified/applied.`);
  } finally {
    await connection.end();
  }
}

/**
 * Runs all seed SQL files in alphanumeric order against the database.
 */
async function runSeeds() {
  const connection = await mysql.createConnection({
    host: env.db.host,
    port: env.db.port,
    user: env.db.user,
    password: env.db.password,
    database: env.db.name,
    multipleStatements: true,
  });

  try {
    const dir = path.join(__dirname, "seeds");
    if (!fs.existsSync(dir)) {
      logger.warn(`Seeds directory not found at: ${dir}`);
      return;
    }

    const files = fs.readdirSync(dir).filter((f) => f.endsWith(".sql")).sort();
    logger.info(`Checking/applying ${files.length} seeds...`);

    for (const file of files) {
      const sql = fs.readFileSync(path.join(dir, file), "utf8");
      await connection.query(sql);
    }

    logger.info(`All ${files.length} seeds verified/applied.`);
  } finally {
    await connection.end();
  }
}

/**
 * Full initialization routine:
 * 1. Ensures database exists.
 * 2. Runs migrations (creates all tables).
 * 3. Runs seeds (populates default reference data/admin if not already present).
 */
async function initDb(options = {}) {
  const autoMigrate = options.autoMigrate ?? (process.env.AUTO_MIGRATE !== "false");
  const autoSeed = options.autoSeed ?? (process.env.AUTO_SEED !== "false");

  if (!autoMigrate) {
    logger.info("Auto-migration is disabled via AUTO_MIGRATE=false");
    return;
  }

  logger.info(`Initializing database "${env.db.name}"...`);
  await createDatabaseIfNotExists();
  await runMigrations();

  if (autoSeed) {
    await runSeeds();
  }

  logger.info(`Database "${env.db.name}" and tables are ready.`);
}

module.exports = {
  createDatabaseIfNotExists,
  runMigrations,
  runSeeds,
  initDb,
};
