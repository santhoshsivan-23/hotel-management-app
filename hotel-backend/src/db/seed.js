/**
 * Runs every .sql file in db/seeds, in filename order. Seeds are written
 * with INSERT IGNORE / ON DUPLICATE KEY UPDATE so this is safe to re-run.
 *
 * Usage: npm run seed
 */
const fs = require("fs");
const path = require("path");
const mysql = require("mysql2/promise");
require("dotenv").config();

async function run() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || "localhost",
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || "root",
    password: process.env.DB_PASSWORD || "",
    database: process.env.DB_NAME || "hotel_db",
    multipleStatements: true,
  });

  const dir = path.join(__dirname, "seeds");
  const files = fs.readdirSync(dir).filter((f) => f.endsWith(".sql")).sort();

  for (const file of files) {
    const sql = fs.readFileSync(path.join(dir, file), "utf8");
    process.stdout.write(`Running seed ${file} ... `);
    await connection.query(sql);
    console.log("done");
  }

  await connection.end();
  console.log(`\nAll ${files.length} seed files applied.`);
}

run().catch((err) => {
  console.error("Seeding failed:", err.message);
  process.exit(1);
});
