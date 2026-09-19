/**
 * End-to-end integration test against a REAL database.
 *
 * Boots the actual Express app in-process (not mocked), runs it on an
 * ephemeral port, and drives it through: login -> create room type ->
 * create room -> search availability -> create booking -> confirm the
 * room disappears from availability -> confirm a double-booking is
 * rejected -> push the same booking through /api/sync/bookings twice and
 * confirm the second push updates rather than duplicates.
 *
 * Requires a configured .env pointing at a MySQL/MariaDB database that
 * has already been migrated (`npm run migrate`) and seeded (`npm run seed`,
 * for the default admin login this test authenticates as).
 *
 * Run with:  node tests/integration/booking-flow.test.js
 * (No test framework wired up - uses Node's built-in assert + fetch.)
 */
const assert = require("assert");
const app = require("../../src/app");
const pool = require("../../src/config/db");

const PORT = 5099;
const BASE = `http://localhost:${PORT}`;

function authHeader(token) {
  return { Authorization: `Bearer ${token}` };
}

async function run() {
  const server = app.listen(PORT);

  try {
    // 1. Login as the seeded admin
    const loginRes = await fetch(`${BASE}/api/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "admin", password: "admin123" }),
    });
    assert.strictEqual(loginRes.status, 200, "admin login should succeed - did you run `npm run seed`?");
    const { accessToken } = await loginRes.json();
    assert.ok(accessToken, "login response should include an accessToken");

    const auth = authHeader(accessToken);

    // 2. Get a room type to attach a fresh test room to
    const roomTypesRes = await fetch(`${BASE}/api/room-types`, { headers: auth });
    const roomTypes = await roomTypesRes.json();
    assert.ok(roomTypes.length > 0, "expected seeded room types to exist");
    const roomTypeId = roomTypes[0].id;

    // 3. Create a uniquely-numbered test room (safe to re-run)
    const roomNumber = `TEST-${Date.now()}`;
    const createRoomRes = await fetch(`${BASE}/api/rooms`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({ room_number: roomNumber, room_type_id: roomTypeId, capacity: 2, price: 1500 }),
    });
    assert.strictEqual(createRoomRes.status, 201, "room creation should succeed");
    const room = await createRoomRes.json();

    const checkIn = "2027-01-10";
    const checkOut = "2027-01-12";

    // 4. Room should be available before any booking
    const availableBefore = await fetch(
      `${BASE}/api/rooms/available?check_in=${checkIn}&check_out=${checkOut}`,
      { headers: auth }
    ).then((r) => r.json());
    assert.ok(
      availableBefore.some((r) => r.id === room.id),
      "freshly created room should appear as available"
    );

    // 5. Create a booking for it
    const bookingRes = await fetch(`${BASE}/api/bookings`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({
        guest: { name: "Integration Test Guest", mobile: "9000000001" },
        room_id: room.id,
        check_in: checkIn,
        check_out: checkOut,
        adults: 1,
        children: 0,
      }),
    });
    assert.strictEqual(bookingRes.status, 201, "booking creation should succeed");
    const booking = await bookingRes.json();
    assert.strictEqual(Number(booking.nights), 2);
    assert.strictEqual(Number(booking.room_total), 3000); // 2 nights x 1500

    // 6. Room should now be excluded from availability for the same dates
    const availableAfter = await fetch(
      `${BASE}/api/rooms/available?check_in=${checkIn}&check_out=${checkOut}`,
      { headers: auth }
    ).then((r) => r.json());
    assert.ok(
      !availableAfter.some((r) => r.id === room.id),
      "booked room should no longer show as available for overlapping dates"
    );

    // 7. A second, overlapping booking on the same room must be rejected
    const overlapRes = await fetch(`${BASE}/api/bookings`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({
        guest: { name: "Should Not Get In", mobile: "9000000002" },
        room_id: room.id,
        check_in: checkIn,
        check_out: checkOut,
        adults: 1,
        children: 0,
      }),
    });
    assert.strictEqual(overlapRes.status, 409, "overlapping booking on the same room must be rejected");

    // 8. Sync idempotency: push the same booking uuid twice via /api/sync/bookings
    const [[guestRow]] = await pool.query("SELECT uuid FROM guests WHERE id = ?", [booking.guest_id]);
    const syncPayload = {
      device_id: "integration-test-device",
      records: [
        {
          uuid: booking.uuid,
          guest_uuid: guestRow.uuid,
          room_id: room.id,
          check_in: booking.check_in,
          check_out: booking.check_out,
          adults: booking.adults,
          children: booking.children,
          room_rate: booking.room_rate,
          nights: booking.nights,
          room_total: booking.room_total,
          discount: booking.discount,
          tax_amount: booking.tax_amount,
          grand_total: booking.grand_total,
          advance_paid: booking.advance_paid,
          status: booking.status,
        },
      ],
    };

    const sync1 = await fetch(`${BASE}/api/sync/bookings`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify(syncPayload),
    }).then((r) => r.json());
    assert.strictEqual(sync1.results[0].status, "updated", "record already exists, so first push here should update");

    const sync2 = await fetch(`${BASE}/api/sync/bookings`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify(syncPayload),
    }).then((r) => r.json());
    assert.strictEqual(sync2.results[0].status, "updated", "resending the same uuid should update, never create");

    const [countRows] = await pool.query("SELECT COUNT(*) AS count FROM bookings WHERE uuid = ?", [booking.uuid]);
    assert.strictEqual(countRows[0].count, 1, "exactly one booking row must exist for this uuid, no duplicates");

    console.log("booking-flow.test.js: all assertions passed");
  } finally {
    server.close();
    await pool.end();
  }
}

run().catch((err) => {
  console.error("Integration test failed:", err);
  process.exitCode = 1;
});
