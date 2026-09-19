import '../app_database.dart';
import '../tables/maintenance_table.dart';

class MaintenanceDao {
  MaintenanceDao(this._db);
  final AppDatabase _db;

  Future<List<Map<String, dynamic>>> findAll({String? status}) async {
    final db = await _db.database;
    return db.query(
      MaintenanceTable.tableName,
      where: status == null ? 'is_deleted = 0' : 'is_deleted = 0 AND status = ?',
      whereArgs: status == null ? null : [status],
      orderBy: 'reported_at DESC',
    );
  }

  Future<void> insert(Map<String, dynamic> row) async {
    final db = await _db.database;
    await db.insert(MaintenanceTable.tableName, row);
  }

  Future<void> updateStatus(String uuid, String status, {String? assignedTo}) async {
    final db = await _db.database;
    final changes = <String, dynamic>{
      'status': status,
      'sync_status': 'PENDING',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (assignedTo != null) changes['assigned_to'] = assignedTo;
    if (status == 'FIXED' || status == 'COMPLETED') {
      changes['fixed_at'] = DateTime.now().toUtc().toIso8601String();
    }
    await db.update(MaintenanceTable.tableName, changes, where: 'uuid = ?', whereArgs: [uuid]);
  }

  Future<List<Map<String, dynamic>>> pending() => _db.getPending(MaintenanceTable.tableName);
}
