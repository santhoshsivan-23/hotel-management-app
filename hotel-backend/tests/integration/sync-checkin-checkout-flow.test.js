/**
 * Verifies the fixes made after cross-checking the Flutter app against
 * this backend:
 *   1. A booking synced with status CHECKED_IN flips the room to OCCUPIED.
 *   2. A booking synced with status CHECKED_OUT flips the room to DIRTY
 *      AND generates a persisted invoice row - exactly like the direct
 *      POST /bookings/:id/checkout endpoint does - even though this
 *      booking was never checked out via that endpoint, only synced.
 *   3. Re-syncing the same uuid never creates a duplicate invoice.
 *
 * Run with:  node tests/integration/sync-checkin-checkout-flow.test.js
 * Requires a migrated + seeded database (same as booking-flow.test.js).
 */
const assert = require("assert");
const app = require("../../src/app");
const pool = require("../../src/config/db");

const PORT = 5098;
const BASE = `http://localhost:${PORT}`;

async function run() {
  const server = app.listen(PORT);

  try {
    const loginRes = await fetch(`${BASE}/api/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "admin", password: "admin123" }),
    });
    const { accessToken } = await loginRes.json();
    const auth = { Authorization: `Bearer ${accessToken}` };

    // Create a room for this test
    const roomTypes = await fetch(`${BASE}/api/room-types`, { headers: auth }).then((r) => r.json());
    const roomNumber = `SY${Date.now()}`.slice(0, 20);
    const room = await fetch(`${BASE}/api/rooms`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({ room_number: roomNumber, room_type_id: roomTypes[0].id, capacity: 2, price: 1800 }),
    }).then((r) => r.json());

    // Simulate the Flutter app: create a guest + booking entirely through
    // sync, exactly as SyncManager would push them after being created
    // offline (device_id, client-generated uuids).
    const guestUuid = crypto.randomUUID();
    const bookingUuid = crypto.randomUUID();
    const deviceId = "integration-test-tablet";

    await fetch(`${BASE}/api/sync/guests`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({
        device_id: deviceId,
        records: [{ uuid: guestUuid, name: "Sync Flow Guest", mobile: "9812345670" }],
      }),
    });

    const basePayload = {
      uuid: bookingUuid,
      guest_uuid: guestUuid,
      room_id: room.id,
      check_in: "2027-02-01",
      check_out: "2027-02-03",
      adults: 1,
      children: 0,
      room_rate: 1800,
      nights: 2,
      room_total: 3600,
      discount: 0,
      tax_amount: 432,
      grand_total: 4032,
      advance_paid: 4032, // fully paid, so checkout won't be blocked by a balance
    };

    // 1) Sync as CONFIRMED (booking creation)
    await fetch(`${BASE}/api/sync/bookings`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({ device_id: deviceId, records: [{ ...basePayload, status: "CONFIRMED" }] }),
    });

    const [[roomAfterBooking]] = await pool.query("SELECT status FROM rooms WHERE id = ?", [room.id]);
    assert.strictEqual(roomAfterBooking.status, "RESERVED", "room should be RESERVED after booking sync");

    // Record the advance payment via sync too, so checkout sees a paid balance
    const paymentUuid = crypto.randomUUID();
    await fetch(`${BASE}/api/sync/payments`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({
        device_id: deviceId,
        records: [{ uuid: paymentUuid, booking_uuid: bookingUuid, amount: 4032, method: "Cash" }],
      }),
    });

    // 2) Sync as CHECKED_IN
    await fetch(`${BASE}/api/sync/bookings`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({ device_id: deviceId, records: [{ ...basePayload, status: "CHECKED_IN" }] }),
    });

    const [[roomAfterCheckin]] = await pool.query("SELECT status FROM rooms WHERE id = ?", [room.id]);
    assert.strictEqual(roomAfterCheckin.status, "OCCUPIED", "room should flip to OCCUPIED on synced check-in");

    // 3) Sync as CHECKED_OUT (this is the offline-checkout path - never
    // touches POST /bookings/:id/checkout at all)
    const checkoutResult = await fetch(`${BASE}/api/sync/bookings`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({ device_id: deviceId, records: [{ ...basePayload, status: "CHECKED_OUT" }] }),
    }).then((r) => r.json());
    assert.strictEqual(checkoutResult.results[0].status, "updated");

    const [[roomAfterCheckout]] = await pool.query("SELECT status FROM rooms WHERE id = ?", [room.id]);
    assert.strictEqual(roomAfterCheckout.status, "DIRTY", "room should flip to DIRTY on synced checkout");

    // The key fix: an invoice row should now exist for this booking, even
    // though it was never checked out through the direct REST endpoint.
    const [[bookingRow]] = await pool.query("SELECT id FROM bookings WHERE uuid = ?", [bookingUuid]);
    const [invoiceRows] = await pool.query("SELECT * FROM invoices WHERE booking_id = ?", [bookingRow.id]);
    assert.strictEqual(invoiceRows.length, 1, "exactly one invoice should be generated for the synced checkout");
    assert.ok(invoiceRows[0].invoice_number, "invoice should have a real invoice_number assigned");
    assert.strictEqual(Number(invoiceRows[0].grand_total), 4032);
    assert.strictEqual(Number(invoiceRows[0].balance), 0, "balance should be zero - fully paid before checkout");

    // 4) Re-sync the exact same CHECKED_OUT payload again (simulating a
    // duplicate sync tap) - must not create a second invoice row.
    await fetch(`${BASE}/api/sync/bookings`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({ device_id: deviceId, records: [{ ...basePayload, status: "CHECKED_OUT" }] }),
    });
    const [invoiceRowsAfterResync] = await pool.query("SELECT * FROM invoices WHERE booking_id = ?", [bookingRow.id]);
    assert.strictEqual(invoiceRowsAfterResync.length, 1, "re-syncing checkout must not duplicate the invoice");

    console.log("sync-checkin-checkout-flow.test.js: all assertions passed");
  } finally {
    server.close();
    await pool.end();
  }
}

run().catch((err) => {
  console.error("Integration test failed:", err);
  process.exitCode = 1;
});
