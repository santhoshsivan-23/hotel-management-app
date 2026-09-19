/// Single-row local cache of hotel/business settings (currency, check-in
/// time, invoice/booking prefixes, ...) so invoices and the dashboard can
/// render correctly while offline. Added for the same reason as the two
/// tables above.
class HotelSettingsTable {
  HotelSettingsTable._();

  static const String tableName = 'hotel_settings';

  /// Exact set of local columns - the backend's rows carry extra fields
  /// (e.g. created_at, or a joined room_type_name) that don't exist in
  /// this local cache table. Every pull filters an incoming server row
  /// down to just these keys before inserting, otherwise sqflite throws
  /// (it builds its INSERT/UPDATE directly from the map's keys).
  static const List<String> columns = ['id', 'hotel_name', 'logo', 'address', 'phone', 'email', 'tax_info', 'currency', 'timezone', 'checkin_time', 'checkout_time', 'invoice_prefix', 'booking_prefix', 'updated_at'];

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id INTEGER PRIMARY KEY,
      hotel_name TEXT,
      logo TEXT,
      address TEXT,
      phone TEXT,
      email TEXT,
      tax_info TEXT,
      currency TEXT NOT NULL DEFAULT 'INR',
      timezone TEXT,
      checkin_time TEXT,
      checkout_time TEXT,
      invoice_prefix TEXT,
      booking_prefix TEXT,
      updated_at TEXT
    );
  ''';
}
