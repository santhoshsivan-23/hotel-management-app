import '../app_database.dart';
import '../tables/housekeeping_table.dart';

class HousekeepingDao {
  HousekeepingDao(this._db);
  final AppDatabase _db;

  Future<List<Map<String, dynamic>>> findAll({String? status}) async {
    final db = await _db.database;
    return db.query(
      HousekeepingTable.tableName,
      where: status == null ? 'is_deleted = 0' : 'is_deleted = 0 AND status = ?',
      whereArgs: status == null ? null : [status],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> insertForRoom(Map<String, dynamic> row) async {
    final db = await _db.database;
    await db.insert(HousekeepingTable.tableName, row);
  }

  Future<void> updateStatus(String uuid, String status) async {
    final db = await _db.database;
    final changes = <String, dynamic>{
      'status': status,
      'sync_status': 'PENDING',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (status == 'CLEANING') changes['started_at'] = DateTime.now().toUtc().toIso8601String();
    if (status == 'AVAILABLE') changes['completed_at'] = DateTime.now().toUtc().toIso8601String();
    await db.update(HousekeepingTable.tableName, changes, where: 'uuid = ?', whereArgs: [uuid]);
  }

  Future<List<Map<String, dynamic>>> pending() => _db.getPending(HousekeepingTable.tableName);
}
