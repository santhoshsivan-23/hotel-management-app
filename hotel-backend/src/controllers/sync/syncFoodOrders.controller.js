const asyncHandler = require("../../utils/asyncHandler");
const pool = require("../../config/db");
const { processBatch, upsertByUuid } = require("../../services/sync.service");
const { generateUuid } = require("../../utils/uuid");

// POST /api/sync/food-orders
const push = asyncHandler(async (req, res) => {
  const { records, device_id } = req.body;

  const results = await processBatch(pool, records, async (conn, r) => {
    const [[booking]] = await conn.query("SELECT id FROM bookings WHERE uuid = ? LIMIT 1", [r.booking_uuid]);
    if (!booking) throw new Error(`Booking with uuid ${r.booking_uuid} not found`);

    const [[guest]] = await conn.query("SELECT id FROM guests WHERE uuid = ? LIMIT 1", [r.guest_uuid]);
    if (!guest) throw new Error(`Guest with uuid ${r.guest_uuid} not found`);

    const items = Array.isArray(r.items) ? r.items : [];
    const totalAmount = items.reduce((sum, i) => sum + i.quantity * i.price, 0);

    const insertValues = {
      uuid: r.uuid,
      booking_id: booking.id,
      room_id: r.room_id,
      guest_id: guest.id,
      status: r.status || "NEW",
      total_amount: totalAmount,
      created_by_device: device_id,
    };
    const updateValues = {
      booking_id: booking.id,
      room_id: r.room_id,
      guest_id: guest.id,
      status: r.status || "NEW",
      total_amount: totalAmount,
    };

    const result = await upsertByUuid(conn, "food_orders", r.uuid, insertValues, updateValues);

    // Items are simplest to keep in sync by replacing the whole set -
    // offline food orders are rarely edited after creation, so this trades
    // a small amount of churn for a lot of simplicity.
    await conn.query("DELETE FROM food_order_items WHERE food_order_id = ?", [result.id]);
    if (items.length > 0) {
      const rows = items.map((i) => [
        generateUuid(), result.id, i.product_name, i.quantity, i.price, i.modifiers || null, i.notes || null,
      ]);
      await conn.query(
        "INSERT INTO food_order_items (uuid, food_order_id, product_name, quantity, price, modifiers, notes) VALUES ?",
        [rows]
      );
    }

    return result;
  });

  res.json({ results });
});

module.exports = { push };
