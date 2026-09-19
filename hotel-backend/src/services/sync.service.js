const logger = require("../utils/logger");

/**
 * The one function every sync controller relies on for idempotency:
 * look the record up by its client-generated `uuid`; if found, UPDATE it,
 * otherwise INSERT it. Because `uuid` carries a UNIQUE constraint in
 * MySQL, sending the exact same record twice (duplicate tap on "Sync",
 * a retried request after a dropped response, ...) can never create two
 * rows - the second attempt just updates the first one again.
 *
 * @param conn          an active mysql2 connection/transaction
 * @param table         table name
 * @param uuid          client-generated uuid for this record
 * @param insertValues  { column: value, ... } used for INSERT (includes uuid)
 * @param updateValues  { column: value, ... } used for UPDATE (excludes uuid)
 */
async function upsertByUuid(conn, table, uuid, insertValues, updateValues) {
  const [existingRows] = await conn.query(`SELECT id FROM ${table} WHERE uuid = ? LIMIT 1`, [uuid]);

  if (existingRows.length > 0) {
    const id = existingRows[0].id;
    const cols = Object.keys(updateValues);
    if (cols.length > 0) {
      const setClause = cols.map((c) => `${c} = ?`).join(", ");
      const values = cols.map((c) => updateValues[c]);
      await conn.query(`UPDATE ${table} SET ${setClause}, updated_at = NOW() WHERE id = ?`, [...values, id]);
    }
    return { status: "updated", id, uuid };
  }

  const cols = Object.keys(insertValues);
  const placeholders = cols.map(() => "?").join(", ");
  const values = cols.map((c) => insertValues[c]);
  const [result] = await conn.query(`INSERT INTO ${table} (${cols.join(", ")}) VALUES (${placeholders})`, values);
  return { status: "created", id: result.insertId, uuid };
}

/**
 * Runs one sync record through `handler` inside its own transaction, so a
 * bad record in a batch doesn't roll back the ones before/after it. Every
 * outcome (including failures) is reported back to the device so its local
 * sync_status can be updated to SYNCED or FAILED accordingly.
 */
async function processBatch(pool, records, handler) {
  const results = [];

  for (const record of records) {
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      const result = await handler(conn, record);
      await conn.commit();
      results.push(result);
    } catch (err) {
      await conn.rollback();
      logger.warn(`Sync record failed (uuid=${record.uuid}): ${err.message}`);
      results.push({ status: "failed", uuid: record.uuid, error: err.message });
    } finally {
      conn.release();
    }
  }

  return results;
}

module.exports = { upsertByUuid, processBatch };
