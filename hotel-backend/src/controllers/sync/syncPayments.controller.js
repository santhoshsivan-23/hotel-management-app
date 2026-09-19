const asyncHandler = require("../../utils/asyncHandler");
const pool = require("../../config/db");
const { processBatch, upsertByUuid } = require("../../services/sync.service");

// POST /api/sync/payments
// Payments are effectively append-only, but the same idempotent upsert is
// still used so a resend after a dropped response never double-charges.
const push = asyncHandler(async (req, res) => {
  const { records, device_id } = req.body;

  const results = await processBatch(pool, records, async (conn, r) => {
    const [[booking]] = await conn.query("SELECT id FROM bookings WHERE uuid = ? LIMIT 1", [r.booking_uuid]);
    if (!booking) throw new Error(`Booking with uuid ${r.booking_uuid} not found`);

    const insertValues = {
      uuid: r.uuid,
      booking_id: booking.id,
      amount: r.amount,
      method: r.method,
      reference_no: r.reference_no || null,
      paid_at: r.paid_at || new Date().toISOString().slice(0, 19).replace("T", " "),
      created_by_device: device_id,
    };
    // Payments shouldn't be edited after the fact from a sync payload -
    // only allow the reference number/notes to change on resend.
    const updateValues = { reference_no: r.reference_no || null };

    return upsertByUuid(conn, "payments", r.uuid, insertValues, updateValues);
  });

  res.json({ results });
});

module.exports = { push };
