/**
 * Runs every .sql file in db/seeds, in filename order. Seeds are written
 * with INSERT IGNORE / ON DUPLICATE KEY UPDATE so this is safe to re-run.
 *
 * Usage: npm run seed
 */
const { runSeeds } = require("./initDb");

async function run() {
  await runSeeds();
}

if (require.main === module) {
  run().catch((err) => {
    console.error("Seeding failed:", err.message);
    process.exit(1);
  });
}

module.exports = { run };

