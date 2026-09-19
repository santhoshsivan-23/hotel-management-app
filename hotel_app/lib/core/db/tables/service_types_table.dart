/// Read-only local cache of service types (Settings -> Service Types).
///
/// Not present in the original file list but required for the app to
/// work offline: the "new service request" screen needs to let a
/// receptionist pick a service type (Laundry, Extra Bed, ...) without a
/// network call, exactly as rooms/room_types/amenities/taxes do. Added
/// following the same reasoning used for the backend's extra reference
/// controllers.
class ServiceTypesTable {
  ServiceTypesTable._();

  static const String tableName = 'service_types';

  /// Exact set of local columns - the backend's rows carry extra fields
  /// (e.g. created_at, or a joined room_type_name) that don't exist in
  /// this local cache table. Every pull filters an incoming server row
  /// down to just these keys before inserting, otherwise sqflite throws
  /// (it builds its INSERT/UPDATE directly from the map's keys).
  static const List<String> columns = ['id', 'uuid', 'name', 'category', 'price', 'tax_percent', 'active', 'updated_at'];

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id INTEGER PRIMARY KEY,
      uuid TEXT,
      name TEXT NOT NULL,
      category TEXT,
      price REAL NOT NULL DEFAULT 0,
      tax_percent REAL NOT NULL DEFAULT 0,
      active INTEGER NOT NULL DEFAULT 1,
      updated_at TEXT
    );
  ''';
}
