import '../app_database.dart';
import '../tables/service_requests_table.dart';
import '../tables/rooms_table.dart';
import '../tables/service_types_table.dart';

class ServiceRequestDao {
  ServiceRequestDao(this._db);
  final AppDatabase _db;

  static const String _joinedSelect = '''
    SELECT sr.*, r.room_number AS room_number, st.name AS service_type_name
    FROM ${ServiceRequestsTable.tableName} sr
    LEFT JOIN ${RoomsTable.tableName} r ON r.id = sr.room_id
    LEFT JOIN ${ServiceTypesTable.tableName} st ON st.id = sr.service_type_id
  ''';

  Future<List<Map<String, dynamic>>> findAll({String? status, String? bookingUuid}) async {
    final db = await _db.database;
    final clauses = <String>['sr.is_deleted = 0'];
    final args = <Object?>[];
    if (status != null) {
      clauses.add('sr.status = ?');
      args.add(status);
    }
    if (bookingUuid != null) {
      clauses.add('sr.booking_uuid = ?');
      args.add(bookingUuid);
    }
    return db.rawQuery(
      '$_joinedSelect WHERE ${clauses.join(' AND ')} ORDER BY sr.created_at DESC',
      args,
    );
  }

  Future<void> insert(Map<String, dynamic> row) async {
    final db = await _db.database;
    await db.insert(ServiceRequestsTable.tableName, row);
  }

  Future<void> updateStatus(String uuid, String status) async {
    final db = await _db.database;
    await db.update(
      ServiceRequestsTable.tableName,
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
      "SELECT COALESCE(SUM(amount), 0) AS total FROM ${ServiceRequestsTable.tableName} "
      "WHERE booking_uuid = ? AND status != 'CANCELLED' AND is_deleted = 0",
      [bookingUuid],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> pending() => _db.getPending(ServiceRequestsTable.tableName);
}
