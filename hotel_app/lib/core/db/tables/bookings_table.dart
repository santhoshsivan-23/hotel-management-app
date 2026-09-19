/// Local booking record. `guest_uuid` links to GuestsTable.uuid (not a
/// server id) so a booking can be created for a guest that hasn't synced
/// yet - both rows travel up together, guest first, per SyncManager's
/// dependency ordering. `room_id` is a real server id because rooms are
/// read-only reference data pulled from the backend, never created
/// offline.
class BookingsTable {
  BookingsTable._();

  static const String tableName = 'bookings';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      uuid TEXT PRIMARY KEY,
      server_id INTEGER,
      booking_number TEXT,
      guest_uuid TEXT NOT NULL,
      room_id INTEGER NOT NULL,
      check_in TEXT NOT NULL,
      check_out TEXT NOT NULL,
      adults INTEGER NOT NULL DEFAULT 1,
      children INTEGER NOT NULL DEFAULT 0,
      room_rate REAL NOT NULL DEFAULT 0,
      nights INTEGER NOT NULL DEFAULT 1,
      room_total REAL NOT NULL DEFAULT 0,
      discount REAL NOT NULL DEFAULT 0,
      tax_amount REAL NOT NULL DEFAULT 0,
      grand_total REAL NOT NULL DEFAULT 0,
      advance_paid REAL NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'CONFIRMED',
      sync_status TEXT NOT NULL DEFAULT 'PENDING',
      sync_error TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      last_synced_at TEXT,
      device_id TEXT,
      is_deleted INTEGER NOT NULL DEFAULT 0
    );
  ''';

  static const String idxRoomDates =
      'CREATE INDEX IF NOT EXISTS idx_bookings_room_dates ON $tableName (room_id, check_in, check_out);';
  static const String idxSyncStatus =
      'CREATE INDEX IF NOT EXISTS idx_bookings_sync_status ON $tableName (sync_status);';
  static const String idxStatus =
      'CREATE INDEX IF NOT EXISTS idx_bookings_status ON $tableName (status);';
}
