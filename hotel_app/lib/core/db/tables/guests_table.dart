/// Local cache/queue for guest profiles created or edited on this device.
/// Every row created offline gets a client uuid immediately - that uuid is
/// the primary key, and is what the backend upserts on when this row is
/// pushed through /api/sync/guests.
class GuestsTable {
  GuestsTable._();

  static const String tableName = 'guests';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      uuid TEXT PRIMARY KEY,
      server_id INTEGER,
      name TEXT NOT NULL,
      mobile TEXT NOT NULL,
      email TEXT,
      id_proof_type TEXT,
      id_proof_number TEXT,
      address TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING',
      sync_error TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      last_synced_at TEXT,
      device_id TEXT,
      is_deleted INTEGER NOT NULL DEFAULT 0
    );
  ''';

  static const String idxMobile =
      'CREATE INDEX IF NOT EXISTS idx_guests_mobile ON $tableName (mobile);';
  static const String idxSyncStatus =
      'CREATE INDEX IF NOT EXISTS idx_guests_sync_status ON $tableName (sync_status);';
}
