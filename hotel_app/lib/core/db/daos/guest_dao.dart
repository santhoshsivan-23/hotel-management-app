import '../app_database.dart';
import '../tables/guests_table.dart';

/// Thin, typed wrapper over AppDatabase for the guests table. Feature
/// repositories (features/guests/data/repositories) sit on top of this and
/// convert the raw maps into Guest model objects.
class GuestDao {
  GuestDao(this._db);
  final AppDatabase _db;

  Future<List<Map<String, dynamic>>> findAll({String? search}) async {
    final db = await _db.database;
    if (search != null && search.trim().isNotEmpty) {
      final like = '%${search.trim()}%';
      return db.query(
        GuestsTable.tableName,
        where: 'is_deleted = 0 AND (name LIKE ? OR mobile LIKE ? OR email LIKE ?)',
        whereArgs: [like, like, like],
        orderBy: 'updated_at DESC',
      );
    }
    return db.query(
      GuestsTable.tableName,
      where: 'is_deleted = 0',
      orderBy: 'updated_at DESC',
    );
  }

  Future<Map<String, dynamic>?> findByUuid(String uuid) async {
    final db = await _db.database;
    final rows = await db.query(GuestsTable.tableName, where: 'uuid = ?', whereArgs: [uuid], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> insert(Map<String, dynamic> row) async {
    final db = await _db.database;
    await db.insert(GuestsTable.tableName, row);
  }

  Future<void> update(String uuid, Map<String, dynamic> changes) async {
    final db = await _db.database;
    await db.update(
      GuestsTable.tableName,
      {
        ...changes,
        'sync_status': 'PENDING', // any local edit must be re-synced
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<void> softDelete(String uuid) async {
    final db = await _db.database;
    await db.update(
      GuestsTable.tableName,
      {'is_deleted': 1, 'sync_status': 'PENDING', 'updated_at': DateTime.now().toUtc().toIso8601String()},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<List<Map<String, dynamic>>> pending() => _db.getPending(GuestsTable.tableName);
}
