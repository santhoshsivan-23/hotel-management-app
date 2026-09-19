import '../app_database.dart';
import '../tables/payments_table.dart';

class PaymentDao {
  PaymentDao(this._db);
  final AppDatabase _db;

  Future<List<Map<String, dynamic>>> findByBooking(String bookingUuid) async {
    final db = await _db.database;
    return db.query(
      PaymentsTable.tableName,
      where: 'booking_uuid = ? AND is_deleted = 0',
      whereArgs: [bookingUuid],
      orderBy: 'paid_at DESC',
    );
  }

  Future<void> insert(Map<String, dynamic> row) async {
    final db = await _db.database;
    await db.insert(PaymentsTable.tableName, row);
  }

  Future<double> totalPaid(String bookingUuid) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM ${PaymentsTable.tableName} '
      'WHERE booking_uuid = ? AND is_deleted = 0',
      [bookingUuid],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> pending() => _db.getPending(PaymentsTable.tableName);
}
