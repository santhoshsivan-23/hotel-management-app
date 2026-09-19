class HousekeepingTable {
  HousekeepingTable._();

  static const String tableName = 'housekeeping_tasks';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      uuid TEXT PRIMARY KEY,
      server_id INTEGER,
      room_id INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'DIRTY',
      started_at TEXT,
      completed_at TEXT,
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

  static const String idxSyncStatus =
      'CREATE INDEX IF NOT EXISTS idx_housekeeping_sync_status ON $tableName (sync_status);';
}
