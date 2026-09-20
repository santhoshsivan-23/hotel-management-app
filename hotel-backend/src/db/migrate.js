/**
 * Minimal migration runner: executes every .sql file in db/migrations, in
 * filename order, against the configured MySQL database. Each file uses
 * CREATE TABLE IF NOT EXISTS, so re-running this script is always safe.
 *
 * Usage: npm run migrate
 */
const { createDatabaseIfNotExists, runMigrations } = require("./initDb");

async function run() {
  await createDatabaseIfNotExists();
  await runMigrations();
}

if (require.main === module) {
  run().catch((err) => {
    console.error("Migration failed:", err.message);
    process.exit(1);
  });
}

module.exports = { run };

