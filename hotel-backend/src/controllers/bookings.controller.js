const asyncHandler = require("../utils/asyncHandler");
const pool = require("../config/db");
const bookingModel = require("../models/booking.model");
const guestModel = require("../models/guest.model");
const paymentModel = require("../models/payment.model");
const roomModel = require("../models/room.model");
const housekeepingModel = require("../models/housekeeping.model");
const bookingService = require("../services/booking.service");
const invoiceService = require("../services/invoice.service");
const notificationService = require("../services/notification.service");
const { generateBookingNumber } = require("../utils/invoiceNumberGenerator");
const { nightsBetween } = require("../utils/dateHelpers");
const { round2 } = require("../utils/currency");

const list = asyncHandler(async (req, res) => {
  const { status, room_id, guest_id, from_date, to_date } = req.query;
  const rows = await bookingModel.findAll({
    status,
    roomId: room_id,
    guestId: guest_id,
    fromDate: from_date,
    toDate: to_date,
  });
  res.json(rows);
});

const getById = asyncHandler(async (req, res) => {
  const booking = await bookingModel.findById(req.params.id);
  if (!booking) return res.status(404).json({ message: "Booking not found" });
  res.json(booking);
});

/**
 * Full "New Reservation" flow in one call: resolve/create guest, re-check
 * availability, compute pricing, insert the booking, and record the
 * advance payment - all inside one transaction so a failure partway
 * through never leaves a half-created booking behind.
 */
const create = asyncHandler(async (req, res) => {
  const body = req.body;

  await bookingService.assertRoomAvailable({ roomId: body.room_id, checkIn: body.check_in, checkOut: body.check_out });

  const pricing = await bookingService.calculatePricing({
    roomRate: (await roomModel.findById(body.room_id)).price,
    checkIn: body.check_in,
    checkOut: body.check_out,
    discount: body.discount || 0,
  });

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    let guestId = body.guest_id;
    if (!guestId) {
      const guest = await guestModel.create(body.guest, conn);
      guestId = guest.id;
    }

    const bookingNumber = await generateBookingNumber();
    const booking = await bookingModel.create(
      {
        booking_number: bookingNumber,
        guest_id: guestId,
        room_id: body.room_id,
        check_in: body.check_in,
        check_out: body.check_out,
        adults: body.adults,
        children: body.children,
        room_rate: (await roomModel.findById(body.room_id)).price,
        nights: pricing.nights,
        room_total: pricing.roomTotal,
        discount: pricing.discount,
        tax_amount: pricing.taxAmount,
        grand_total: pricing.grandTotal,
        advance_paid: body.advance_paid || 0,
        status: "CONFIRMED",
      },
      conn
    );

    if (body.advance_paid > 0) {
      await paymentModel.create(
        { booking_id: booking.id, amount: body.advance_paid, method: body.payment_method || "Cash" },
        conn
      );
    }

    await conn.query("UPDATE rooms SET status = 'RESERVED' WHERE id = ?", [body.room_id]);

    await conn.commit();
    notificationService.sendBookingConfirmation(booking);
    res.status(201).json(booking);
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
});

const updateStatus = asyncHandler(async (req, res) => {
  const booking = await bookingModel.updateStatus(req.params.id, req.body.status);
  if (!booking) return res.status(404).json({ message: "Booking not found" });
  res.json(booking);
});

const cancel = asyncHandler(async (req, res) => {
  const booking = await bookingModel.findById(req.params.id);
  if (!booking) return res.status(404).json({ message: "Booking not found" });

  await bookingModel.updateStatus(booking.id, "CANCELLED");
  await roomModel.updateStatus(booking.room_id, "AVAILABLE");
  res.json({ message: "Booking cancelled" });
});

// POST /api/bookings/:id/checkin
const checkin = asyncHandler(async (req, res) => {
  const booking = await bookingModel.findById(req.params.id);
  if (!booking) return res.status(404).json({ message: "Booking not found" });
  if (booking.status !== "CONFIRMED") {
    return res.status(409).json({ message: `Cannot check in a booking with status ${booking.status}` });
  }

  const updated = await bookingModel.updateStatus(booking.id, "CHECKED_IN");
  await roomModel.updateStatus(booking.room_id, "OCCUPIED");
  res.json(updated);
});

// POST /api/bookings/:id/checkout
const checkout = asyncHandler(async (req, res) => {
  const booking = await bookingModel.findById(req.params.id);
  if (!booking) return res.status(404).json({ message: "Booking not found" });
  if (booking.status !== "CHECKED_IN") {
    return res.status(409).json({ message: `Cannot check out a booking with status ${booking.status}` });
  }

  const invoiceResult = await invoiceService.buildInvoice(booking.id, { persist: true });
  if (invoiceResult.balance > 0 && !req.body.allow_pending_balance) {
    return res.status(409).json({
      message: `Balance of ${invoiceResult.balance} must be collected before checkout`,
      invoice: invoiceResult,
    });
  }

  // If early checkout, record actual departure time so room is immediately free
  if (new Date(booking.check_out) > new Date()) {
    await pool.query("UPDATE bookings SET check_out = NOW(), updated_at = NOW() WHERE id = ?", [booking.id]);
  }

  await bookingModel.updateStatus(booking.id, "CHECKED_OUT");
  await roomModel.updateStatus(booking.room_id, "DIRTY");
  await housekeepingModel.createForRoom(booking.room_id);

  res.json({ message: "Checked out", invoice: invoiceResult });
});

// POST /api/bookings/:id/reopen
const reopen = asyncHandler(async (req, res) => {
  const booking = await bookingModel.findById(req.params.id);
  if (!booking) return res.status(404).json({ message: "Booking not found" });
  if (booking.status !== "CHECKED_OUT") {
    return res.status(409).json({
      message: `Can only reopen a booking with status CHECKED_OUT (current: ${booking.status})`,
    });
  }

  await bookingModel.updateStatus(booking.id, "CHECKED_IN");
  res.json({ message: "Booking reopened for adjustments", booking: await bookingModel.findById(booking.id) });
});

// POST /api/bookings/:id/change-room
const changeRoom = asyncHandler(async (req, res) => {
  const booking = await bookingModel.findById(req.params.id);
  if (!booking) return res.status(404).json({ message: "Booking not found" });

  await bookingService.assertRoomAvailable({
    roomId: req.body.room_id,
    checkIn: booking.check_in,
    checkOut: booking.check_out,
    excludeBookingId: booking.id,
  });

  const oldRoomId = booking.room_id;
  const updated = await bookingModel.updateRoom(booking.id, req.body.room_id);

  if (booking.status === "CHECKED_IN") {
    await roomModel.updateStatus(req.body.room_id, "OCCUPIED");
    await roomModel.updateStatus(oldRoomId, "AVAILABLE");
  } else {
    await roomModel.updateStatus(req.body.room_id, "RESERVED");
    await roomModel.updateStatus(oldRoomId, "AVAILABLE");
  }

  res.json(updated);
});

// POST /api/bookings/:id/extend
const extendStay = asyncHandler(async (req, res) => {
  const booking = await bookingModel.findById(req.params.id);
  if (!booking) return res.status(404).json({ message: "Booking not found" });

  await bookingService.assertRoomAvailable({
    roomId: booking.room_id,
    checkIn: booking.check_in,
    checkOut: req.body.check_out,
    excludeBookingId: booking.id,
  });

  const pricing = await bookingService.calculatePricing({
    roomRate: booking.room_rate,
    checkIn: booking.check_in,
    checkOut: req.body.check_out,
    discount: booking.discount,
  });

  const updated = await bookingModel.extendStay(
    booking.id,
    req.body.check_out,
    pricing.nights,
    pricing.roomTotal,
    round2(pricing.roomTotal - pricing.discount + pricing.taxAmount)
  );
  res.json(updated);
});

const runningBill = asyncHandler(async (req, res) => {
  const result = await invoiceService.buildInvoice(req.params.id, { persist: false });
  res.json(result);
});

module.exports = {
  list, getById, create, updateStatus, cancel, checkin, checkout, reopen, changeRoom, extendStay, runningBill,
};
