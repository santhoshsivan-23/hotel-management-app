import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'tables/guests_table.dart';
import 'tables/bookings_table.dart';
import 'tables/rooms_table.dart';
import 'tables/room_types_table.dart';
import 'tables/amenities_table.dart';
import 'tables/food_orders_table.dart';
import 'tables/food_order_items_table.dart';
import 'tables/service_requests_table.dart';
import 'tables/payments_table.dart';
import 'tables/taxes_table.dart';
import 'tables/maintenance_table.dart';
import 'tables/housekeeping_table.dart';
import 'tables/service_types_table.dart';
import 'tables/payment_methods_table.dart';
import 'tables/hotel_settings_table.dart';
import 'tables/sync_meta_table.dart';

/// The device's entire offline store. Every screen reads/writes here and
/// *only* here - the UI never talks to the network directly (see
/// core/sync/sync_manager.dart for the only place that does).
///
/// Uses plain sqflite (no code generation step) so the project builds with
/// nothing more than `flutter pub get` - no build_runner required.
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  static const int _dbVersion = 1;
  static const String _dbName = 'hotel_app.db';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        final batch = db.batch();

        // Syncable (offline-writable) tables
        batch.execute(GuestsTable.createTableSql);
        batch.execute(GuestsTable.idxMobile);
        batch.execute(GuestsTable.idxSyncStatus);

        batch.execute(BookingsTable.createTableSql);
        batch.execute(BookingsTable.idxRoomDates);
        batch.execute(BookingsTable.idxSyncStatus);
        batch.execute(BookingsTable.idxStatus);

        batch.execute(FoodOrdersTable.createTableSql);
        batch.execute(FoodOrdersTable.idxBooking);
        batch.execute(FoodOrdersTable.idxSyncStatus);

        batch.execute(FoodOrderItemsTable.createTableSql);
        batch.execute(FoodOrderItemsTable.idxFoodOrder);

        batch.execute(ServiceRequestsTable.createTableSql);
        batch.execute(ServiceRequestsTable.idxBooking);
        batch.execute(ServiceRequestsTable.idxSyncStatus);

        batch.execute(PaymentsTable.createTableSql);
        batch.execute(PaymentsTable.idxBooking);
        batch.execute(PaymentsTable.idxSyncStatus);

        batch.execute(MaintenanceTable.createTableSql);
        batch.execute(MaintenanceTable.idxSyncStatus);

        batch.execute(HousekeepingTable.createTableSql);
        batch.execute(HousekeepingTable.idxSyncStatus);

        // Read-only reference-data caches (pulled from the server)
        batch.execute(RoomsTable.createTableSql);
        batch.execute(RoomTypesTable.createTableSql);
        batch.execute(AmenitiesTable.createTableSql);
        batch.execute(TaxesTable.createTableSql);
        batch.execute(ServiceTypesTable.createTableSql);
        batch.execute(PaymentMethodsTable.createTableSql);
        batch.execute(HotelSettingsTable.createTableSql);

        // Sync bookkeeping
        batch.execute(SyncMetaTable.createTableSql);

        await batch.commit(noResult: true);
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ---------------------------------------------------------------------
  // Generic helpers shared by every syncable-table DAO
  // ---------------------------------------------------------------------

  /// Rows still needing a push - this is exactly what SyncManager sends
  /// for a given table on every "Sync Now" tap.
  Future<List<Map<String, dynamic>>> getPending(String table) async {
    final db = await database;
    return db.query(
      table,
      where: "sync_status IN ('PENDING', 'FAILED') AND is_deleted = 0",
    );
  }

  Future<int> countPending(String table) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS count FROM $table WHERE sync_status IN ('PENDING', 'FAILED') AND is_deleted = 0",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Sum of countPending() across every syncable table - drives the badge
  /// text ("12 pending") and whether "Sync Now" is enabled at all.
  Future<int> countAllPending() async {
    const tables = [
      GuestsTable.tableName,
      BookingsTable.tableName,
      FoodOrdersTable.tableName,
      ServiceRequestsTable.tableName,
      PaymentsTable.tableName,
      MaintenanceTable.tableName,
      HousekeepingTable.tableName,
    ];
    var total = 0;
    for (final table in tables) {
      total += await countPending(table);
    }
    return total;
  }

  Future<void> markSynced(String table, String uuid, {int? serverId, Map<String, dynamic>? extraFields}) async {
    final db = await database;
    await db.update(
      table,
      {
        'sync_status': 'SYNCED',
        'sync_error': null,
        if (serverId != null) 'server_id': serverId,
        'last_synced_at': DateTime.now().toUtc().toIso8601String(),
        ...?extraFields,
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<void> markFailed(String table, String uuid, String error) async {
    final db = await database;
    await db.update(
      table,
      {'sync_status': 'FAILED', 'sync_error': error},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  // ---------------------------------------------------------------------
  // Reference-data cache helpers (rooms, room_types, amenities, taxes,
  // service_types, payment_methods) - simple replace-by-id upserts.
  // ---------------------------------------------------------------------

  /// [allowedColumns], when given, strips any key from each row that
  /// isn't a real local column before inserting - the backend's raw rows
  /// commonly carry extra fields (created_at, a joined display name, ...)
  /// that this local cache table was never given a column for, and
  /// sqflite's insert() builds SQL straight from the map's keys, so an
  /// unfiltered row would throw. Pass the table's own `columns` constant
  /// (see e.g. RoomsTable.columns) as this argument.
  Future<void> upsertReferenceRows(
    String table,
    List<Map<String, dynamic>> rows, {
    List<String>? allowedColumns,
  }) async {
    if (rows.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final row in rows) {
      final filtered = allowedColumns == null
          ? row
          : {for (final key in allowedColumns) if (row.containsKey(key)) key: row[key]};
      batch.insert(table, filtered, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getReferenceRows(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<String?> getSyncCursor(String key) async {
    final db = await database;
    final rows = await db.query(
      SyncMetaTable.tableName,
      where: 'meta_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['meta_value'] as String?;
  }

  Future<void> setSyncCursor(String key, String value) async {
    final db = await database;
    await db.insert(
      SyncMetaTable.tableName,
      {'meta_key': key, 'meta_value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Wipes every local table - used by "Log out" and by the debug/reset
  /// option recommended for any offline-first app in settings.
  Future<void> resetAll() async {
    final db = await database;
    const tables = [
      GuestsTable.tableName,
      BookingsTable.tableName,
      FoodOrdersTable.tableName,
      FoodOrderItemsTable.tableName,
      ServiceRequestsTable.tableName,
      PaymentsTable.tableName,
      MaintenanceTable.tableName,
      HousekeepingTable.tableName,
      RoomsTable.tableName,
      RoomTypesTable.tableName,
      AmenitiesTable.tableName,
      TaxesTable.tableName,
      ServiceTypesTable.tableName,
      PaymentMethodsTable.tableName,
      HotelSettingsTable.tableName,
      SyncMetaTable.tableName,
    ];
    final batch = db.batch();
    for (final table in tables) {
      batch.delete(table);
    }
    await batch.commit(noResult: true);
  }
}
