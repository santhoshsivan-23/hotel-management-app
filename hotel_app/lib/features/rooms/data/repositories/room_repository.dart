import 'package:dio/dio.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/db/daos/room_dao.dart';
import '../../../../core/db/tables/rooms_table.dart';
import '../../../../core/network/api_client.dart';
import '../models/room_model.dart';

/// Rooms are read *locally* (offline-first, from the cache SyncManager
/// keeps fresh) but written *online* (create/update/status-change go
/// straight to the API) - rooms are admin/back-office data per the
/// hybrid design, not something a receptionist creates while offline.
class RoomRepository {
  RoomRepository({required AppDatabase database, required ApiClient apiClient})
      : _dao = RoomDao(database),
        _database = database,
        _apiClient = apiClient;

  final RoomDao _dao;
  final AppDatabase _database;
  final ApiClient _apiClient;

  Future<List<RoomModel>> findAll({String? status}) async {
    final rows = await _dao.findAll(status: status);
    return rows.map(RoomModel.fromMap).toList();
  }

  Future<List<RoomModel>> findAvailable({
    required DateTime checkIn,
    required DateTime checkOut,
    int? capacity,
    int? roomTypeId,
  }) async {
    final rows = await _dao.findAvailable(
      checkInIso: checkIn.toUtc().toIso8601String(),
      checkOutIso: checkOut.toUtc().toIso8601String(),
      capacity: capacity,
      roomTypeId: roomTypeId,
    );
    return rows.map(RoomModel.fromMap).toList();
  }

  /// Throws DioException if offline/failed - callers should surface a
  /// clear "connect to add a room" message, matching the settings screens.
  Future<void> create({
    required String roomNumber,
    required int roomTypeId,
    String? floor,
    required int capacity,
    required double price,
  }) async {
    final response = await _apiClient.dio.post(ApiEndpoints.rooms, data: {
      'room_number': roomNumber,
      'room_type_id': roomTypeId,
      'floor': floor,
      'capacity': capacity,
      'price': price,
    });
    // The API response also carries a joined room_type_name and
    // created_at that this local cache table has no column for - parse
    // into RoomModel and re-serialize to just the cached columns rather
    // than inserting the raw response map.
    final room = RoomModel.fromMap(Map<String, dynamic>.from(response.data as Map));
    await _database.upsertReferenceRows(RoomsTable.tableName, [room.toCacheMap()], allowedColumns: RoomsTable.columns);
  }

  Future<void> updateStatus(int roomId, String status) async {
    final response = await _apiClient.dio.patch(ApiEndpoints.roomStatus(roomId), data: {'status': status});
    final room = RoomModel.fromMap(Map<String, dynamic>.from(response.data as Map));
    await _database.upsertReferenceRows(RoomsTable.tableName, [room.toCacheMap()], allowedColumns: RoomsTable.columns);
  }

  bool isDioOffline(Object error) => error is DioException && error.type != DioExceptionType.badResponse;
}
