class ServiceRequestsTable {
  ServiceRequestsTable._();

  static const String tableName = 'service_requests';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      uuid TEXT PRIMARY KEY,
      server_id INTEGER,
      booking_uuid TEXT NOT NULL,
      room_id INTEGER NOT NULL,
      guest_uuid TEXT NOT NULL,
      service_type_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL DEFAULT 1,
      amount REAL NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'REQUESTED',
      notes TEXT,
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
      'CREATE INDEX IF NOT EXISTS idx_service_requests_booking ON $tableName (booking_uuid);';
  static const String idxSyncStatus =
      'CREATE INDEX IF NOT EXISTS idx_service_requests_sync_status ON $tableName (sync_status);';
}
