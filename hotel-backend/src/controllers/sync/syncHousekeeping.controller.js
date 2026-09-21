const asyncHandler = require("../../utils/asyncHandler");
const pool = require("../../config/db");
const { processBatch, upsertByUuid } = require("../../services/sync.service");

// POST /api/sync/housekeeping
const push = asyncHandler(async (req, res) => {
  const { records, device_id } = req.body;

  const results = await processBatch(pool, records, async (conn, r) => {
    const [[room]] = await conn.query("SELECT id FROM rooms WHERE id = ? LIMIT 1", [r.room_id]);
    if (!room) throw new Error(`Room ${r.room_id} not found`);

    const insertValues = {
      uuid: r.uuid,
      room_id: r.room_id,
      status: r.status || "DIRTY",
      started_at: r.started_at || null,
      completed_at: r.completed_at || null,
      notes: r.notes || null,
    };
    const updateValues = {
      status: r.status || "DIRTY",
      started_at: r.started_at || null,
      completed_at: r.completed_at || null,
      notes: r.notes || null,
    };

    const result = await upsertByUuid(conn, "housekeeping_tasks", r.uuid, insertValues, updateValues);

    if (r.status === "AVAILABLE") {
      const [upcoming] = await conn.query(
        `SELECT id FROM bookings 
         WHERE room_id = ? 
           AND status IN ('CONFIRMED', 'PENDING') 
           AND check_out > NOW() 
         LIMIT 1`,
        [r.room_id]
      );
      const newRoomStatus = upcoming.length > 0 ? "RESERVED" : "AVAILABLE";
      await conn.query("UPDATE rooms SET status = ? WHERE id = ?", [newRoomStatus, r.room_id]);
    } else if (r.status === "CLEANING") {
      await conn.query("UPDATE rooms SET status = 'CLEANING' WHERE id = ?", [r.room_id]);
    }

    return result;
  });

  res.json({ results });
});

module.exports = { push };
