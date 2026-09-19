class PaymentsTable {
  PaymentsTable._();

  static const String tableName = 'payments';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      uuid TEXT PRIMARY KEY,
      server_id INTEGER,
      booking_uuid TEXT NOT NULL,
      amount REAL NOT NULL,
      method TEXT NOT NULL,
      reference_no TEXT,
      paid_at TEXT NOT NULL,
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
      'CREATE INDEX IF NOT EXISTS idx_payments_booking ON $tableName (booking_uuid);';
  static const String idxSyncStatus =
      'CREATE INDEX IF NOT EXISTS idx_payments_sync_status ON $tableName (sync_status);';
}
