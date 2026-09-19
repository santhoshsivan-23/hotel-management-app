/// Read-only local cache of rooms, pulled from GET /api/sync/reference-data
/// and refreshed on every sync. Rooms are never created offline, so this
/// table has no sync_status/uuid-as-pk machinery - `id` IS the server id.
class RoomsTable {
  RoomsTable._();

  static const String tableName = 'rooms';

  /// Exact set of local columns - the backend's rows carry extra fields
  /// (e.g. created_at, or a joined room_type_name) that don't exist in
  /// this local cache table. Every pull filters an incoming server row
  /// down to just these keys before inserting, otherwise sqflite throws
  /// (it builds its INSERT/UPDATE directly from the map's keys).
  static const List<String> columns = ['id', 'uuid', 'room_number', 'room_type_id', 'floor', 'capacity', 'price', 'status', 'updated_at'];

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id INTEGER PRIMARY KEY,
      uuid TEXT,
      room_number TEXT NOT NULL,
      room_type_id INTEGER NOT NULL,
      floor TEXT,
      capacity INTEGER NOT NULL DEFAULT 2,
      price REAL NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'AVAILABLE',
      updated_at TEXT
    );
  ''';
}
