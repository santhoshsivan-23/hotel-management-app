/// Tiny key/value table used only by the sync layer to remember the
/// delta-pull cursor per reference-data endpoint (the `since` timestamp
/// the backend echoes back as `server_time` - see
/// core/sync/endpoints/reference_data_api.dart).
class SyncMetaTable {
  SyncMetaTable._();

  static const String tableName = 'sync_meta';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      meta_key TEXT PRIMARY KEY,
      meta_value TEXT
    );
  ''';
}
