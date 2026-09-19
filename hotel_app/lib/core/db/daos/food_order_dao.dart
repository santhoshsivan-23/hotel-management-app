import '../app_database.dart';
import '../tables/food_orders_table.dart';
import '../tables/food_order_items_table.dart';
import '../tables/rooms_table.dart';

class FoodOrderDao {
  FoodOrderDao(this._db);
  final AppDatabase _db;

  static const String _joinedSelect = '''
    SELECT fo.*, r.room_number AS room_number
    FROM ${FoodOrdersTable.tableName} fo
    LEFT JOIN ${RoomsTable.tableName} r ON r.id = fo.room_id
  ''';

  Future<List<Map<String, dynamic>>> findAll({String? status, String? bookingUuid}) async {
    final db = await _db.database;
    final clauses = <String>['fo.is_deleted = 0'];
    final args = <Object?>[];
    if (status != null) {
      clauses.add('fo.status = ?');
      args.add(status);
    }
    if (bookingUuid != null) {
      clauses.add('fo.booking_uuid = ?');
      args.add(bookingUuid);
    }
    return db.rawQuery(
      '$_joinedSelect WHERE ${clauses.join(' AND ')} ORDER BY fo.created_at DESC',
      args,
    );
  }

  Future<Map<String, dynamic>?> findByUuid(String uuid) async {
    final db = await _db.database;
    final rows = await db.rawQuery('$_joinedSelect WHERE fo.uuid = ? LIMIT 1', [uuid]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> itemsFor(String foodOrderUuid) async {
    final db = await _db.database;
    return db.query(
      FoodOrderItemsTable.tableName,
      where: 'food_order_uuid = ?',
      whereArgs: [foodOrderUuid],
    );
  }

  Future<void> insertWithItems(Map<String, dynamic> order, List<Map<String, dynamic>> items) async {
    final db = await _db.database;
    final batch = db.batch();
    batch.insert(FoodOrdersTable.tableName, order);
    for (final item in items) {
      batch.insert(FoodOrderItemsTable.tableName, item);
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateStatus(String uuid, String status) async {
    final db = await _db.database;
    await db.update(
      FoodOrdersTable.tableName,
      {
        'status': status,
        'sync_status': 'PENDING',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<double> totalForBooking(String bookingUuid) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(total_amount), 0) AS total FROM ${FoodOrdersTable.tableName} "
      "WHERE booking_uuid = ? AND status != 'CANCELLED' AND is_deleted = 0",
      [bookingUuid],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> pending() => _db.getPending(FoodOrdersTable.tableName);
}
