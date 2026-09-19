/// Read-only local cache of amenities (Settings -> Amenities).
class AmenitiesTable {
  AmenitiesTable._();

  static const String tableName = 'amenities';

  /// Exact set of local columns - the backend's rows carry extra fields
  /// (e.g. created_at, or a joined room_type_name) that don't exist in
  /// this local cache table. Every pull filters an incoming server row
  /// down to just these keys before inserting, otherwise sqflite throws
  /// (it builds its INSERT/UPDATE directly from the map's keys).
  static const List<String> columns = ['id', 'uuid', 'name', 'active', 'updated_at'];

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id INTEGER PRIMARY KEY,
      uuid TEXT,
      name TEXT NOT NULL,
      active INTEGER NOT NULL DEFAULT 1,
      updated_at TEXT
    );
  ''';
}
