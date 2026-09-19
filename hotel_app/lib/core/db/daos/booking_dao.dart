import '../app_database.dart';
import '../tables/bookings_table.dart';
import '../tables/guests_table.dart';
import '../tables/rooms_table.dart';

class BookingDao {
  BookingDao(this._db);
  final AppDatabase _db;

  static const String _joinedSelect = '''
    SELECT b.*, g.name AS guest_name, g.mobile AS guest_mobile, r.room_number AS room_number
    FROM ${BookingsTable.tableName} b
    LEFT JOIN ${GuestsTable.tableName} g ON g.uuid = b.guest_uuid
    LEFT JOIN ${RoomsTable.tableName} r ON r.id = b.room_id
  ''';

  Future<List<Map<String, dynamic>>> findAll({String? status, int? roomId}) async {
    final db = await _db.database;
    final clauses = <String>['b.is_deleted = 0'];
    final args = <Object?>[];
    if (status != null) {
      clauses.add('b.status = ?');
      args.add(status);
    }
    if (roomId != null) {
      clauses.add('b.room_id = ?');
      args.add(roomId);
    }
    return db.rawQuery(
      '$_joinedSelect WHERE ${clauses.join(' AND ')} ORDER BY b.check_in DESC',
      args,
    );
  }

  Future<Map<String, dynamic>?> findByUuid(String uuid) async {
    final db = await _db.database;
    final rows = await db.rawQuery('$_joinedSelect WHERE b.uuid = ? LIMIT 1', [uuid]);
    return rows.isEmpty ? null : rows.first;
  }

  /// Local availability pre-check (mirrors the backend's overlap rule):
  /// existing.check_in < new.check_out AND existing.check_out > new.check_in.
  /// This lets the "search available rooms" step work instantly offline;
  /// the backend still re-validates on sync as the final authority.
  Future<bool> hasOverlap({
    required int roomId,
    required String checkInIso,
    required String checkOutIso,
    String? excludeUuid,
  }) async {
    final db = await _db.database;
    final clauses = [
      'room_id = ?',
      "status IN ('PENDING','CONFIRMED','CHECKED_IN')",
      'check_in < ?',
      'check_out > ?',
      'is_deleted = 0',
    ];
    final args = <Object?>[roomId, checkOutIso, checkInIso];
    if (excludeUuid != null) {
      clauses.add('uuid != ?');
      args.add(excludeUuid);
    }
    final rows = await db.query(
      BookingsTable.tableName,
      where: clauses.join(' AND '),
      whereArgs: args,
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> insert(Map<String, dynamic> row) async {
    final db = await _db.database;
    await db.insert(BookingsTable.tableName, row);
  }

  Future<void> update(String uuid, Map<String, dynamic> changes, {bool markPending = true}) async {
    final db = await _db.database;
    await db.update(
      BookingsTable.tableName,
      {
        ...changes,
        if (markPending) 'sync_status': 'PENDING',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<void> updateStatus(String uuid, String status) => update(uuid, {'status': status});

  Future<List<Map<String, dynamic>>> pending() => _db.getPending(BookingsTable.tableName);
}
