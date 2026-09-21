import '../app_database.dart';
import '../tables/rooms_table.dart';
import '../tables/room_types_table.dart';
import '../tables/bookings_table.dart';

/// Rooms are read-only reference data locally (see rooms_table.dart) -
/// this DAO only ever reads the cache that reference_data_api.dart
/// refreshes; it never writes rooms back up to the server.
class RoomDao {
  RoomDao(this._db);
  final AppDatabase _db;

  Future<List<Map<String, dynamic>>> findAll({String? status, int? roomTypeId}) async {
    final db = await _db.database;
    final clauses = <String>[];
    final args = <Object?>[];
    if (status != null) {
      clauses.add('status = ?');
      args.add(status);
    }
    if (roomTypeId != null) {
      clauses.add('room_type_id = ?');
      args.add(roomTypeId);
    }
    return db.query(
      RoomsTable.tableName,
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: clauses.isEmpty ? null : args,
      orderBy: 'room_number ASC',
    );
  }

  Future<Map<String, dynamic>?> findById(int id) async {
    final db = await _db.database;
    final rows = await db.query(RoomsTable.tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Local "search available rooms" step of the New Reservation wizard -
  /// works fully offline against the cached room list + cached bookings.
  Future<List<Map<String, dynamic>>> findAvailable({
    required String checkInIso,
    required String checkOutIso,
    int? capacity,
    int? roomTypeId,
  }) async {
    final db = await _db.database;
    final clauses = <String>["r.status NOT IN ('MAINTENANCE', 'OUT_OF_SERVICE')"];
    final args = <Object?>[];

    if (capacity != null) {
      clauses.add('r.capacity >= ?');
      args.add(capacity);
    }
    if (roomTypeId != null) {
      clauses.add('r.room_type_id = ?');
      args.add(roomTypeId);
    }

    final candidateRooms = await db.rawQuery(
      '''
      SELECT r.*, rt.name AS room_type_name
      FROM ${RoomsTable.tableName} r
      LEFT JOIN ${RoomTypesTable.tableName} rt ON rt.id = r.room_type_id
      WHERE ${clauses.join(' AND ')}
      ORDER BY r.price ASC
      ''',
      args,
    );

    final overlapping = await db.rawQuery(
      '''
      SELECT DISTINCT room_id FROM ${BookingsTable.tableName}
      WHERE status IN ('PENDING','CONFIRMED','CHECKED_IN')
        AND is_deleted = 0
        AND check_in < ?
        AND check_out > ?
      ''',
      [checkOutIso, checkInIso],
    );
    final bookedRoomIds = overlapping.map((r) {
      final rid = r['room_id'];
      return (rid is num) ? rid.toInt() : int.tryParse(rid?.toString() ?? '');
    }).whereType<int>().toSet();

    return candidateRooms.where((room) {
      final rid = room['id'];
      final idInt = (rid is num) ? rid.toInt() : int.tryParse(rid?.toString() ?? '');
      return idInt != null && !bookedRoomIds.contains(idInt);
    }).toList();
  }

  /// Local "search room availability status" - returns both available and unavailable/booked rooms
  /// with their overlapping booking details, fully offline against cached rooms + cached bookings.
  Future<Map<String, List<Map<String, dynamic>>>> findAvailabilityStatus({
    required String checkInIso,
    required String checkOutIso,
    int? capacity,
    int? roomTypeId,
  }) async {
    final db = await _db.database;
    final clauses = <String>[];
    final args = <Object?>[];

    if (capacity != null) {
      clauses.add('r.capacity >= ?');
      args.add(capacity);
    }
    if (roomTypeId != null) {
      clauses.add('r.room_type_id = ?');
      args.add(roomTypeId);
    }

    final candidateRooms = await db.rawQuery(
      '''
      SELECT r.*, rt.name AS room_type_name
      FROM ${RoomsTable.tableName} r
      LEFT JOIN ${RoomTypesTable.tableName} rt ON rt.id = r.room_type_id
      ${clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}'}
      ORDER BY r.price ASC
      ''',
      args,
    );

    final overlapping = await db.rawQuery(
      '''
      SELECT b.room_id, b.check_in, b.check_out, b.booking_number
      FROM ${BookingsTable.tableName} b
      WHERE b.status IN ('PENDING','CONFIRMED','CHECKED_IN')
        AND b.is_deleted = 0
        AND b.check_in < ?
        AND b.check_out > ?
      ''',
      [checkOutIso, checkInIso],
    );

    final overlapMap = <int, List<Map<String, dynamic>>>{};
    for (final row in overlapping) {
      final rid = row['room_id'];
      final idInt = (rid is num) ? rid.toInt() : int.tryParse(rid?.toString() ?? '');
      if (idInt != null) {
        overlapMap.putIfAbsent(idInt, () => []).add(row);
      }
    }

    final available = <Map<String, dynamic>>[];
    final unavailable = <Map<String, dynamic>>[];

    for (final room in candidateRooms) {
      final rid = room['id'];
      final idInt = (rid is num) ? rid.toInt() : int.tryParse(rid?.toString() ?? '');
      final status = room['status']?.toString();

      if (status == 'MAINTENANCE' || status == 'OUT_OF_SERVICE') {
        unavailable.add({
          ...room,
          'reason': status,
          'conflicts': [],
        });
      } else if (idInt != null && overlapMap.containsKey(idInt)) {
        unavailable.add({
          ...room,
          'reason': 'BOOKED',
          'conflicts': overlapMap[idInt],
        });
      } else {
        available.add(room);
      }
    }

    return {
      'available': available,
      'unavailable': unavailable,
    };
  }

  Future<void> replaceAll(List<Map<String, dynamic>> rows) => _db.upsertReferenceRows(RoomsTable.tableName, rows);
}
