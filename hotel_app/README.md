# Hotel App — Flutter Frontend (Hybrid Offline/Online)

Flutter front-end for the hotel management system, built against the
`hotel-backend` Node/Express/MySQL API. Every operational screen
(guests, bookings, food orders, room services, payments, maintenance,
housekeeping) works **fully offline** from a local SQLite cache; a manual
**"Sync Now"** control pushes pending changes once the device has real
internet — matching the hybrid design from the implementation plan this
project was built from.

## 1. Requirements

- Flutter SDK 3.19+ (Dart 3.3+)
- Android Studio / Xcode for platform builds
- The `hotel-backend` API running and reachable from the device/emulator

## 2. Setup

This archive ships `lib/`, `pubspec.yaml`, and `test/` only — it does **not**
include the generated `android/` and `ios/` platform projects (those are
build tooling, not application code, and are best generated fresh by the
Flutter SDK you're building with). To get a runnable project:

```bash
# 1. Create a fresh Flutter project shell, then copy this lib/ and pubspec.yaml over it
flutter create hotel_app_shell
cp -r lib hotel_app_shell/lib
cp pubspec.yaml hotel_app_shell/pubspec.yaml
cp -r test hotel_app_shell/test
cd hotel_app_shell

# 2. Install dependencies (no code generation step - plain sqflite, no build_runner)
flutter pub get

# 3. Point the app at your backend and run
flutter run --dart-define=API_BASE_URL=http://<your-backend-host>:5000/api
```

`API_BASE_URL` defaults to `http://10.0.2.2:5000/api` (the Android
emulator's alias for the host machine's `localhost`) if you don't pass
`--dart-define` — see `lib/core/config/env.dart`.

### Default login

Use whatever admin user your `hotel-backend` was seeded with (its README
seeds `admin` / `admin123`).

## 3. Architecture at a glance

```
UI (screens/providers)
   |
   v
Repositories  (features/*/data/repositories)   <- the ONLY thing UI talks to
   |
   v
DAOs (core/db/daos)  ---->  SQLite (core/db/app_database.dart)
   ^
   |
SyncManager (core/sync/sync_manager.dart)  <-- the ONLY thing that talks
   |                                            to the network
   v
Node/Express backend (hotel-backend)
```

- **Nothing in a screen or repository calls the network directly.** Every
  write (new guest, new booking, food order, service request, payment,
  maintenance report, housekeeping update) goes straight into the local
  SQLite cache with `sync_status = 'PENDING'` and a client-generated
  `uuid`.
- **`SyncStatusBadge`** (top-right of every screen) is the only sync
  control. It's hidden while offline, shows a pending count while online,
  and only sends anything when tapped — see
  `core/widgets/sync_status_badge.dart`.
- **`SyncManager.syncAll()`** (`core/sync/sync_manager.dart`) is the only
  place that talks to the backend for pushing local changes: it pushes
  guests → bookings → food orders → service requests → payments →
  maintenance → housekeeping, in that dependency order, then pulls fresh
  reference data (rooms, room types, amenities, taxes, service types,
  payment methods, hotel settings) and other devices' active bookings.
- **Idempotency**: because the backend's `/api/sync/*` endpoints upsert by
  the client-generated `uuid`, re-tapping "Sync Now" (or a retried request
  after a dropped connection) can only ever update the same row — never
  create a duplicate. Once a local row's `sync_status` becomes `SYNCED`,
  it's excluded from every future push (see
  `AppDatabase.getPending()`).
- **Reference/admin data is different on purpose**: rooms, room types,
  amenities, service types, taxes, payment methods, users & roles, and
  hotel settings are managed **online** (Settings screens call the API
  directly) and only ever **pulled down** for offline reading — they are
  never created offline, matching the original architecture notes.

## 4. Backend ↔ Flutter connection — verified

This app was cross-checked against `hotel-backend` (in the same archive)
endpoint-by-endpoint and field-by-field — every `ApiEndpoints` constant
against the actual mounted Express routes, every sync push payload's field
names against what each `sync*.controller.js` reads, and every pulled
response shape against what the local SQLite cache can actually store.
Three real bugs were found and fixed in that pass:

- **`ApiEndpoints` had the wrong path for pulling other devices' active
  bookings** (`/sync/bookings/bookings`, which doesn't exist) — fixed to
  `/sync/reference-data/bookings`, the backend's real route.
- **Reference-data pulls (rooms, room types, amenities, taxes, service
  types, payment methods, hotel settings) would have thrown** once real
  data existed. The backend's `SELECT *` rows include a `created_at`
  column (and rooms include a joined `room_type_name`) that the local
  cache tables don't define — `sqflite`'s `insert()` builds its SQL
  directly from the map's keys, so an unfiltered row throws. Fixed with a
  `columns` allow-list on every reference table (see e.g.
  `RoomsTable.columns`) that `AppDatabase.upsertReferenceRows()` now
  filters every incoming row against before inserting.
- **`AuthService.tryRefresh()` existed but was never called anywhere** —
  an expired access token would just fail with no recovery. Fixed with a
  401-retry interceptor in `ApiClient` (`onUnauthorized`, wired up in
  `main.dart` once both `ApiClient` and `AuthService` exist), so one
  refresh-and-retry now happens automatically.

Also fixed to match the backend's own behavior for online check-in/
checkout: a synced `booking_number` now gets written back onto the local
row (it no longer shows "Pending" forever after a successful sync), and
check-in/checkout/change-room now update the local room-status cache
immediately rather than waiting for the next pull.

See `hotel-backend/README.md` for the matching write-up from the backend
side, including the server-side fixes (room status + invoice generation
now also happen for a checkout that arrives through sync, not just
through the direct REST endpoint).

## 5. What's included vs. the original file tree

Implemented exactly as specified, plus a few files added where the app
genuinely needed them to work (documented in the code where added):

- `core/db/tables/service_types_table.dart`, `payment_methods_table.dart`,
  `hotel_settings_table.dart`, `sync_meta_table.dart` — reference-data
  caches and a sync-cursor table the original list didn't enumerate, but
  the offline screens (service picker, payment method picker, delta-pull
  cursor) need them.
- `features/settings/_shared/` — a small generic "list + add/edit form"
  screen (`reference_crud_screen.dart`) and field-config class
  (`reference_field.dart`) that Room Types, Amenities, Service Types,
  Tax & Charges, and Payment Methods all configure and reuse, instead of
  five nearly-identical hand-written screens.
- `features/reports/_shared/report_table.dart` — likewise, one generic
  "fetch a report endpoint, render as a table" widget the six report
  screens configure.
- `features/payments_billing/presentation/screens/payments_billing_screen.dart`
  — the sidebar's "Payments & Billing" landing page (outstanding balances
  list), since the original tree only specified the booking-level
  sub-screens (running bill / take payment / invoice).
- `features/checkin_checkout/presentation/screens/active_stay_screen.dart`
  is a thin, explicitly-named wrapper over `ReservationDetailsScreen`
  (a checked-in booking's active-stay view and its reservation-details
  view show identical information and actions).
- **Maintenance and Housekeeping** have full data-layer support (local
  tables, DAOs, and sync endpoints all exist and were built and tested)
  but no dedicated UI screens, since the given Flutter file tree didn't
  include a feature folder for either — worth adding if the app needs a
  dedicated maintenance/housekeeping UI later.
- Native `android/` and `ios/` platform folders are intentionally not
  included — see the Setup section above for why and how to generate them.

## 6. Local database

Plain `sqflite` (raw SQL, no `build_runner`/code generation) — see
`core/db/app_database.dart` for the full schema. Every offline-writable
table carries the same sync bookkeeping columns:
`uuid, server_id, sync_status, sync_error, created_at, updated_at,
last_synced_at, device_id, is_deleted`.
