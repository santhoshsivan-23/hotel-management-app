/// Local in-room food order. `booking_uuid`/`guest_uuid` reference local
/// uuids (both may still be pending sync themselves), `room_id` is a real
/// server id from the read-only rooms cache.
class FoodOrdersTable {
  FoodOrdersTable._();

  static const String tableName = 'food_orders';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      uuid TEXT PRIMARY KEY,
      server_id INTEGER,
      booking_uuid TEXT NOT NULL,
      room_id INTEGER NOT NULL,
      guest_uuid TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'NEW',
      total_amount REAL NOT NULL DEFAULT 0,
      sync_status TEXT NOT NULL DEFAULT 'PENDING',
      sync_error TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      last_synced_at TEXT,
      device_id TEXT,
      is_deleted INTEGER NOT NULL DEFAULT 0
    );
  ''';

  static const String idxBooking =
      'CREATE INDEX IF NOT EXISTS idx_food_orders_booking ON $tableName (booking_uuid);';
  static const String idxSyncStatus =
      'CREATE INDEX IF NOT EXISTS idx_food_orders_sync_status ON $tableName (sync_status);';
}
