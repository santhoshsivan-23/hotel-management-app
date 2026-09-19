class MaintenanceTable {
  MaintenanceTable._();

  static const String tableName = 'maintenance_requests';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      uuid TEXT PRIMARY KEY,
      server_id INTEGER,
      room_id INTEGER NOT NULL,
      issue TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'REPORTED',
      assigned_to TEXT,
      notes TEXT,
      reported_at TEXT NOT NULL,
      fixed_at TEXT,
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
      'CREATE INDEX IF NOT EXISTS idx_maintenance_sync_status ON $tableName (sync_status);';
}
