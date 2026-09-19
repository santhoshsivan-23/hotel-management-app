const asyncHandler = require("../../utils/asyncHandler");
const pool = require("../../config/db");

// GET /api/sync/reference-data?since=<ISO timestamp>
// Delta-pull for data the device only ever reads: rooms, room types,
// amenities, taxes, service types, payment methods. The device stores the
// `server_time` from the response as its `since` cursor for next time.
const pull = asyncHandler(async (req, res) => {
  const since = req.query.since || "1970-01-01 00:00:00";

  const [rooms] = await pool.query("SELECT * FROM rooms WHERE updated_at > ?", [since]);
  const [roomTypes] = await pool.query("SELECT * FROM room_types WHERE updated_at > ?", [since]);
  const [amenities] = await pool.query("SELECT * FROM amenities WHERE updated_at > ?", [since]);
  const [taxes] = await pool.query("SELECT * FROM taxes WHERE updated_at > ?", [since]);
  const [serviceTypes] = await pool.query("SELECT * FROM service_types WHERE updated_at > ?", [since]);
  const [paymentMethods] = await pool.query("SELECT * FROM payment_methods WHERE updated_at > ?", [since]);
  const [hotelSettings] = await pool.query("SELECT * FROM hotel_settings LIMIT 1");

  res.json({
    rooms,
    roomTypes,
    amenities,
    taxes,
    serviceTypes,
    paymentMethods,
    hotelSettings: hotelSettings[0] || null,
    server_time: new Date().toISOString(),
  });
});

// GET /api/sync/bookings?since=<ISO timestamp>
// Lets a device refresh its local view of bookings created by *other*
// devices/counters, so its own availability search stays accurate.
const pullBookings = asyncHandler(async (req, res) => {
  const since = req.query.since || "1970-01-01 00:00:00";
  const [rows] = await pool.query(
    `SELECT uuid, room_id, check_in, check_out, status FROM bookings
     WHERE updated_at > ? AND status IN ('PENDING','CONFIRMED','CHECKED_IN')`,
    [since]
  );
  res.json({ bookings: rows, server_time: new Date().toISOString() });
});

module.exports = { pull, pullBookings };
