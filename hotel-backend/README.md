# Hotel Backend — Node.js + Express + MySQL

Backend for the hotel management app, built to serve the **hybrid
offline/online Flutter app**: reference data (rooms, room types, taxes,
etc.) is pulled down for local caching, and everything a receptionist
creates offline (guests, bookings, food orders, service requests,
payments, maintenance, housekeeping) is pushed up through idempotent
`/api/sync/*` endpoints once the device is back online and the user taps
"Sync".

This has been built, migrated, seeded, and smoke-tested end-to-end against
a real MySQL-compatible database (MariaDB) as part of putting this together
— see "What was tested" below.

## 1. Requirements

- Node.js 18+
- MySQL 8+ or MariaDB 10.6+

## 2. Setup

```bash
cd hotel-backend
npm install
cp .env.example .env
# edit .env with your DB credentials, JWT secrets, etc.

npm start          # or: npm run dev (nodemon)
```

> **Note:** Starting the backend with `npm start` or `npm run dev` **automatically**:
> 1. Creates the database (e.g. `hotel_db`) if it doesn't already exist.
> 2. Runs all 20 migrations (creating all tables using `CREATE TABLE IF NOT EXISTS`).
> 3. Runs all 8 seeds (safely inserting default roles, admin user, room types, etc.).
>
> You can also still run migrations or seeds manually if needed:
> ```bash
> npm run migrate   # creates database and all 20 tables manually
> npm run seed      # seeds default data manually
> ```

The server starts on `PORT` (default `5000`) and logs to the console.

### Default login (created by the seed)

```
username: admin
password: admin123
```

**Change this password after first login** — there's no reset flow wired
up yet; update it directly via `users` table / a new endpoint if needed.

## 3. Project layout

See the project tree for the full breakdown — in short:

```
src/
  config/       env, MySQL pool, shared constants (statuses, roles)
  routes/       one file per module, + routes/sync/* for the offline-sync API
  controllers/  request handling, + controllers/sync/* (idempotent upserts)
  services/     booking availability & pricing, invoice building,
                the generic sync upsert helper, reports
  models/       raw SQL query functions (mysql2/promise, no ORM)
  middleware/   JWT auth, role-based access, validation, error handling
  validators/   Joi schemas
  db/           migrations/ (schema) + seeds/ (reference data) + runners
  jobs/         optional daily report job (not scheduled by default)
```

## 4. Core REST API (`/api/...`, all require `Authorization: Bearer <token>` except `/api/auth/login`)

```
POST   /api/auth/login
POST   /api/auth/refresh
GET    /api/auth/me

GET    /api/guests                     GET /api/guests/:id
POST   /api/guests                     PUT /api/guests/:id      DELETE /api/guests/:id

GET    /api/rooms                      GET /api/rooms/available?check_in=&check_out=&capacity=
GET    /api/rooms/:id                  POST /api/rooms          PUT /api/rooms/:id
PATCH  /api/rooms/:id/status           DELETE /api/rooms/:id

GET    /api/bookings                   GET /api/bookings/:id
GET    /api/bookings/:id/running-bill
POST   /api/bookings                   PATCH /api/bookings/:id/status
POST   /api/bookings/:id/cancel        POST /api/bookings/:id/checkin
POST   /api/bookings/:id/checkout      POST /api/bookings/:id/change-room
POST   /api/bookings/:id/extend

GET    /api/food-orders                POST /api/food-orders     PATCH /api/food-orders/:id/status
GET    /api/service-requests           POST /api/service-requests PATCH /api/service-requests/:id/status
GET    /api/payments/booking/:bookingId POST /api/payments
GET    /api/invoices/booking/:bookingId POST /api/invoices/booking/:bookingId/generate
GET    /api/maintenance                POST /api/maintenance     PATCH /api/maintenance/:id/status
GET    /api/housekeeping               PATCH /api/housekeeping/:id/status

GET    /api/reports/bookings | occupancy | revenue | food-sales | room-services | payments | outstanding

GET    /api/room-types  /api/amenities  /api/service-types  /api/taxes  /api/payment-methods   (CRUD)
GET    /api/users  POST /api/users  PATCH /api/users/:id/status     (Admin only)
GET    /api/roles
GET    /api/hotel-settings   PUT /api/hotel-settings                (Admin only)
```

## 5. Offline-sync API (`/api/sync/...`)

Every push endpoint takes the same envelope:

```json
{
  "device_id": "tablet-01",
  "records": [ { "uuid": "...", "...fields": "..." } ]
}
```

```
POST /api/sync/guests
POST /api/sync/bookings            (needs guest_uuid already synced)
POST /api/sync/food-orders         (needs booking_uuid + guest_uuid already synced)
POST /api/sync/service-requests    (needs booking_uuid + guest_uuid already synced)
POST /api/sync/payments            (needs booking_uuid already synced)
POST /api/sync/maintenance
POST /api/sync/housekeeping

GET  /api/sync/reference-data?since=<ISO timestamp>   (pull: rooms, room types, amenities,
                                                         taxes, service types, payment methods,
                                                         hotel settings)
GET  /api/sync/bookings?since=<ISO timestamp>          (pull: other devices' active bookings,
                                                         for accurate local availability checks)
```

**Why a record can never be synced twice:** every record carries a
client-generated `uuid` (the Flutter app creates it the moment the record
is saved locally, before any network call). Each push handler looks the
record up by `uuid` first — if it exists, it's updated in place; if not,
it's inserted. `uuid` also has a `UNIQUE` constraint in MySQL, so even a
retried/duplicated request can only ever update the same row, never insert
a second one. This was verified directly (see below): sending the exact
same guest and booking sync payload twice in a row leaves exactly one row
in the database each time.

Dependent records (bookings, food orders, service requests, payments) are
looked up by their **uuid**, so push order matters: guests before bookings,
bookings before food orders/services/payments — matching the Flutter
`SyncManager.syncAll()` order from the app-side implementation plan.

## 6. What was tested while building this

Using a local MariaDB instance:

- `npm run migrate` — all 20 tables created successfully.
- `npm run seed` — roles, hotel settings, room types, amenities, service
  types, taxes, payment methods, and the default admin user all seeded.
- `POST /api/auth/login` — issued a valid JWT for the seeded admin.
- `POST /api/rooms` + `GET /api/rooms/available` — room creation and the
  date-overlap availability search both work.
- `POST /api/bookings` — created a real booking with computed pricing
  (3 nights × ₹2,000 + 12% room tax = ₹6,720 grand total) and an advance
  payment, and correctly marked the room `RESERVED`.
- Re-querying `/api/rooms/available` for the same dates correctly excluded
  the now-booked room, and a second, overlapping `POST /api/bookings` for
  the same room correctly failed with `409 Room ... is not available`.
- **Sync idempotency**: pushed the same guest sync payload twice — first
  call `status: "created"`, second call `status: "updated"`, and a direct
  `SELECT COUNT(*) ... WHERE uuid = ?` confirmed exactly **one** row.
  Repeated the same test for a booking sync (which also resolves a
  `guest_uuid` foreign key and re-checks room overlap) with the same
  result: one row, no duplicate, and the booking number stays stable
  across repeated syncs.
- `GET /api/sync/reference-data` — correctly returned the seeded rooms,
  room types, taxes, service types and payment methods for the device's
  local cache.
- `role_permissions` seed verified: Admin has all 21 permissions, Manager
  20 (everything but `manage_users`), Receptionist 8 (matching the
  Receptionist permission list in the app spec), Housekeeping 3, Kitchen 2.
- `tests/integration/booking-flow.test.js` codifies all of the above as a
  repeatable, automated check (see below) rather than one-off manual curls.

Every `.js` file in the project also passes `node --check` (110 files).

## 7. Running the tests

```bash
# Fast, no DB required:
node tests/unit/dateHelpers.test.js

# Full integration test - boots the real app in-process on an ephemeral
# port and drives it through booking creation, overlap rejection, and
# sync idempotency against your configured database. Requires the DB to
# already be migrated + seeded (the test logs in as the seeded admin):
npm run migrate && npm run seed
node tests/integration/booking-flow.test.js
```

## 8. Backend ↔ Flutter connection — verified

The Flutter app in this same archive (`hotel_app/`) was cross-checked
against this backend endpoint-by-endpoint and field-by-field. Three real
bugs were found and fixed as part of that pass:

- **Wrong pull-bookings path**: the Flutter app was calling
  `GET /api/sync/bookings/bookings` (doesn't exist) instead of
  `GET /api/sync/reference-data/bookings` (the real route, see
  `referenceData.controller.js#pullBookings`). Fixed on the Flutter side.
- **Offline check-in/checkout never updated room status or generated an
  invoice server-side.** The direct `POST /bookings/:id/checkin` and
  `POST /bookings/:id/checkout` REST endpoints update the room's status
  (and, for checkout, build a persisted invoice) — but a status change
  made *offline* and pushed through the generic `POST /api/sync/bookings`
  upsert didn't replicate any of that. Fixed here in
  `syncBookings.controller.js`: it now detects status transitions
  (`CHECKED_IN` → room `OCCUPIED`, `CHECKED_OUT` → room `DIRTY` + a
  persisted invoice generated after the transaction commits, `CANCELLED`/
  `NO_SHOW` → room `AVAILABLE`) and a changed `room_id` (old room frees up,
  new room takes the right status), so an offline-then-synced check-in or
  checkout now has the exact same server-side effect as doing it online.
  Covered by `tests/integration/sync-checkin-checkout-flow.test.js`.
- **Reference-data pull would have thrown on the Flutter side** once real
  data existed — the backend's `SELECT *` rows carry a `created_at` column
  (and rooms carry a joined `room_type_name`) that the Flutter app's local
  cache tables don't define; inserting an unfiltered row into `sqflite`
  throws. Fixed on the Flutter side (rows are now filtered to each local
  table's real columns before insert).

See `hotel_app/README.md` for the matching write-up from the Flutter side.

## 9. Notes / things to wire up before production

- Swap the placeholder `notification.service.js` for a real SMS/email
  provider if guest confirmations/invoices need to go out automatically.
- `hotel_settings` is a single-row table; `PUT /api/hotel-settings` upserts
  it.
- Role permissions are currently enforced with a simple `requireRole(...)`
  middleware per route; the `roles`/`permissions`/`role_permissions` tables
  exist if finer-grained permission checks are wanted later.
- CORS is wide open (`CORS_ORIGIN=*`) by default for local development —
  lock this down to your app's actual origins before deploying.
