/**
 * Minimal migration runner: executes every .sql file in db/migrations, in
 * filename order, against the configured MySQL database. Each file uses
 * CREATE TABLE IF NOT EXISTS, so re-running this script is always safe.
 *
 * Usage: npm run migrate
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
    multipleStatements: true,
  });

  const dbName = process.env.DB_NAME || "hotel_db";
  await connection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\` CHARACTER SET utf8mb4`);
  await connection.query(`USE \`${dbName}\``);

  const dir = path.join(__dirname, "migrations");
  const files = fs.readdirSync(dir).filter((f) => f.endsWith(".sql")).sort();

  for (const file of files) {
    const sql = fs.readFileSync(path.join(dir, file), "utf8");
    process.stdout.write(`Running migration ${file} ... `);
    await connection.query(sql);
    console.log("done");
  }

  await connection.end();
  console.log(`\nAll ${files.length} migrations applied to database "${dbName}".`);
}

run().catch((err) => {
  console.error("Migration failed:", err.message);
  process.exit(1);
});
