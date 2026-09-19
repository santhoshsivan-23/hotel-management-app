const asyncHandler = require("../../utils/asyncHandler");
const pool = require("../../config/db");
const { processBatch, upsertByUuid } = require("../../services/sync.service");

// POST /api/sync/service-requests
const push = asyncHandler(async (req, res) => {
  const { records, device_id } = req.body;

  const results = await processBatch(pool, records, async (conn, r) => {
    const [[booking]] = await conn.query("SELECT id FROM bookings WHERE uuid = ? LIMIT 1", [r.booking_uuid]);
    if (!booking) throw new Error(`Booking with uuid ${r.booking_uuid} not found`);

    const [[guest]] = await conn.query("SELECT id FROM guests WHERE uuid = ? LIMIT 1", [r.guest_uuid]);
    if (!guest) throw new Error(`Guest with uuid ${r.guest_uuid} not found`);

    const [[serviceType]] = await conn.query("SELECT id, price FROM service_types WHERE id = ? LIMIT 1", [r.service_type_id]);
    if (!serviceType) throw new Error(`Service type ${r.service_type_id} not found`);

    const amount = r.amount ?? Number(serviceType.price) * (r.quantity || 1);

    const insertValues = {
      uuid: r.uuid,
      booking_id: booking.id,
      room_id: r.room_id,
      guest_id: guest.id,
      service_type_id: r.service_type_id,
      quantity: r.quantity || 1,
      amount,
      status: r.status || "REQUESTED",
      notes: r.notes || null,
      created_by_device: device_id,
    };
    const updateValues = {
      booking_id: booking.id,
      room_id: r.room_id,
      guest_id: guest.id,
      service_type_id: r.service_type_id,
      quantity: r.quantity || 1,
      amount,
      status: r.status || "REQUESTED",
      notes: r.notes || null,
    };

    return upsertByUuid(conn, "service_requests", r.uuid, insertValues, updateValues);
  });

  res.json({ results });
});

module.exports = { push };
