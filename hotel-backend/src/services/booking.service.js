const pool = require("../config/db");
const roomModel = require("../models/room.model");
const bookingModel = require("../models/booking.model");
const { nightsBetween, rangesOverlap } = require("../utils/dateHelpers");
const { round2 } = require("../utils/currency");

/**
 * Server-side availability re-check. This is deliberately re-run here
 * (not just trusted from the client's earlier "search available rooms"
 * step) because time may have passed - including records arriving via
 * offline sync that were created before another booking took the room.
 */
async function assertRoomAvailable({ roomId, checkIn, checkOut, excludeBookingId }) {
  const [[room]] = await pool.query("SELECT * FROM rooms WHERE id = ?", [roomId]);
  if (!room) {
    const err = new Error("Room not found");
    err.status = 404;
    throw err;
  }
  if (room.status === "MAINTENANCE" || room.status === "OUT_OF_SERVICE") {
    const err = new Error(`Room ${room.room_number} is not bookable (${room.status})`);
    err.status = 409;
    throw err;
  }

  const overlap = await bookingModel.hasOverlap({ roomId, checkIn, checkOut, excludeBookingId });
  if (overlap) {
    const err = new Error(`Room ${room.room_number} is not available for the selected dates`);
    err.status = 409;
    throw err;
  }

  return room;
}

/**
 * Computes room total, tax, and grand total for a stay.
 * Tax is pulled from the `taxes` table (rows applicable_to = 'ROOM' or 'ALL').
 */
async function calculatePricing({ roomRate, checkIn, checkOut, discount = 0 }) {
  const nights = nightsBetween(checkIn, checkOut);
  const roomTotal = round2(roomRate * nights);
  const subtotal = round2(roomTotal - discount);

  const [taxRows] = await pool.query(
    "SELECT percentage FROM taxes WHERE active = 1 AND (applicable_to = 'ROOM' OR applicable_to = 'ALL')"
  );
  const taxPercent = taxRows.reduce((sum, t) => sum + Number(t.percentage), 0);
  const taxAmount = round2((subtotal * taxPercent) / 100);
  const grandTotal = round2(subtotal + taxAmount);

  return { nights, roomTotal, discount, taxAmount, grandTotal, taxPercent };
}

module.exports = { assertRoomAvailable, calculatePricing, rangesOverlap };
