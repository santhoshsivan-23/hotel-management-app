const asyncHandler = require("../../utils/asyncHandler");
const pool = require("../../config/db");
const { processBatch, upsertByUuid } = require("../../services/sync.service");
const { generateBookingNumber } = require("../../utils/invoiceNumberGenerator");
const invoiceService = require("../../services/invoice.service");

// POST /api/sync/bookings
// Expects each record's guest to already exist server-side (guest_uuid),
// which is why the device syncs `guests` before `bookings` - see
// SyncManager.syncAll() on the Flutter side.
const push = asyncHandler(async (req, res) => {
  const { records, device_id } = req.body;
  const bookingIdsNeedingInvoice = [];

  const results = await processBatch(pool, records, async (conn, r) => {
    const [[guest]] = await conn.query("SELECT id FROM guests WHERE uuid = ? LIMIT 1", [r.guest_uuid]);
    if (!guest) {
      throw new Error(`Guest with uuid ${r.guest_uuid} not found - sync guests before bookings`);
    }

    const [[room]] = await conn.query("SELECT id FROM rooms WHERE id = ? LIMIT 1", [r.room_id]);
    if (!room) {
      throw new Error(`Room ${r.room_id} not found`);
    }

    // Final overlap guard - protects against two devices booking the same
    // room offline before either had a chance to sync.
    const [overlapRows] = await conn.query(
      `SELECT id FROM bookings WHERE room_id = ? AND uuid != ?
         AND status IN ('PENDING','CONFIRMED','CHECKED_IN')
         AND check_in < ? AND check_out > ?`,
      [r.room_id, r.uuid, r.check_out, r.check_in]
    );
    if (overlapRows.length > 0) {
      throw new Error(`Room ${r.room_id} already booked for overlapping dates`);
    }

    const [[existing]] = await conn.query(
      "SELECT booking_number, status, room_id FROM bookings WHERE uuid = ? LIMIT 1",
      [r.uuid]
    );
    const bookingNumber = existing ? existing.booking_number : (r.booking_number || (await generateBookingNumber()));
    const previousStatus = existing ? existing.status : null;
    const previousRoomId = existing ? existing.room_id : null;
    const newStatus = r.status || "CONFIRMED";

    const insertValues = {
      uuid: r.uuid,
      booking_number: bookingNumber,
      guest_id: guest.id,
      room_id: r.room_id,
      check_in: r.check_in,
      check_out: r.check_out,
      adults: r.adults || 1,
      children: r.children || 0,
      room_rate: r.room_rate,
      nights: r.nights,
      room_total: r.room_total,
      discount: r.discount || 0,
      tax_amount: r.tax_amount || 0,
      grand_total: r.grand_total,
      advance_paid: r.advance_paid || 0,
      status: newStatus,
      created_by_device: device_id,
    };
    const updateValues = {
      guest_id: guest.id,
      room_id: r.room_id,
      check_in: r.check_in,
      check_out: r.check_out,
      adults: r.adults || 1,
      children: r.children || 0,
      room_rate: r.room_rate,
      nights: r.nights,
      room_total: r.room_total,
      discount: r.discount || 0,
      tax_amount: r.tax_amount || 0,
      grand_total: r.grand_total,
      advance_paid: r.advance_paid || 0,
      status: newStatus,
    };

    const result = await upsertByUuid(conn, "bookings", r.uuid, insertValues, updateValues);

    // Replicate the same room-status side effects the direct REST
    // endpoints (bookings.controller.js: checkin/checkout/cancel/
    // change-room) apply, so a status or room change made offline has the
    // same effect once synced - whether the receptionist tapped the
    // action with signal or without it.
    if (result.status === "created") {
      await conn.query("UPDATE rooms SET status = 'RESERVED' WHERE id = ? AND status = 'AVAILABLE'", [r.room_id]);
    } else {
      const roomChanged = previousRoomId !== null && previousRoomId !== r.room_id;

      if (roomChanged) {
        // Old room frees up, new room takes on whatever status the
        // booking's current stage implies.
        await conn.query("UPDATE rooms SET status = 'AVAILABLE' WHERE id = ?", [previousRoomId]);
        await conn.query("UPDATE rooms SET status = ? WHERE id = ?", [
          newStatus === "CHECKED_IN" ? "OCCUPIED" : "RESERVED",
          r.room_id,
        ]);
      }

      if (previousStatus !== newStatus) {
        if (newStatus === "CHECKED_IN") {
          await conn.query("UPDATE rooms SET status = 'OCCUPIED' WHERE id = ?", [r.room_id]);
        } else if (newStatus === "CANCELLED" || newStatus === "NO_SHOW") {
          await conn.query("UPDATE rooms SET status = 'AVAILABLE' WHERE id = ?", [r.room_id]);
        } else if (newStatus === "CHECKED_OUT") {
          await conn.query("UPDATE rooms SET status = 'DIRTY' WHERE id = ?", [r.room_id]);
          // Invoice generation reads through the shared pool (a separate
          // connection), so it must happen AFTER this transaction commits -
          // otherwise it would run against a connection that can't yet see
          // the row this same transaction just wrote. Queued here, built below.
          bookingIdsNeedingInvoice.push(result.id);
        }
      }
    }

    return { ...result, booking_number: bookingNumber };
  });

  // Now that every record's transaction has committed, generate invoices
  // for any booking that transitioned to CHECKED_OUT during this batch -
  // exactly like the direct POST /bookings/:id/checkout endpoint does.
  for (const bookingId of bookingIdsNeedingInvoice) {
    try {
      await invoiceService.buildInvoice(bookingId, { persist: true });
    } catch (invoiceErr) {
      // Don't fail the sync response over invoice generation - the
      // booking/payment/charge data is already safely committed; the
      // invoice can be regenerated later via
      // POST /invoices/booking/:id/generate if this ever fails.
    }
  }

  res.json({ results });
});

module.exports = { push };
