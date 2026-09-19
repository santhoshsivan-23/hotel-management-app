const asyncHandler = require("../../utils/asyncHandler");
const pool = require("../../config/db");
const { processBatch, upsertByUuid } = require("../../services/sync.service");

// POST /api/sync/maintenance
const push = asyncHandler(async (req, res) => {
  const { records, device_id } = req.body;

  const results = await processBatch(pool, records, async (conn, r) => {
    const [[room]] = await conn.query("SELECT id FROM rooms WHERE id = ? LIMIT 1", [r.room_id]);
    if (!room) throw new Error(`Room ${r.room_id} not found`);

    const insertValues = {
      uuid: r.uuid,
      room_id: r.room_id,
      issue: r.issue,
      status: r.status || "REPORTED",
      assigned_to: r.assigned_to || null,
      notes: r.notes || null,
      reported_at: r.reported_at || new Date().toISOString().slice(0, 19).replace("T", " "),
      created_by_device: device_id,
    };
    const updateValues = {
      status: r.status || "REPORTED",
      assigned_to: r.assigned_to || null,
      notes: r.notes || null,
    };

    const result = await upsertByUuid(conn, "maintenance_requests", r.uuid, insertValues, updateValues);

    if (r.status === "REPORTED" || r.status === "ASSIGNED" || r.status === "IN_PROGRESS") {
      await conn.query("UPDATE rooms SET status = 'MAINTENANCE' WHERE id = ?", [r.room_id]);
    } else if (r.status === "COMPLETED" || r.status === "FIXED") {
      await conn.query("UPDATE rooms SET status = 'AVAILABLE' WHERE id = ? AND status = 'MAINTENANCE'", [r.room_id]);
    }

    return result;
  });

  res.json({ results });
});

module.exports = { push };
