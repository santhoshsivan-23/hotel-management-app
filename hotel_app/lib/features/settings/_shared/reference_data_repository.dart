import 'package:dio/dio.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/api_client.dart';

/// Generic repository for simple reference-data entities (room types,
/// amenities, service types, taxes, payment methods). These are managed
/// online (they're the data every device *pulls*, not something created
/// offline), so create/update/delete call the backend directly. When
/// there's no connection, list() falls back to the same local cache
/// SyncManager refreshes on every "Sync Now", shown read-only.
class ReferenceDataRepository {
  ReferenceDataRepository({
    required ApiClient apiClient,
    required AppDatabase database,
    required this.endpoint,
    required this.localTable,
  })  : _apiClient = apiClient,
        _database = database;

  final ApiClient _apiClient;
  final AppDatabase _database;
  final String endpoint;
  final String localTable;

  Future<({List<Map<String, dynamic>> items, bool isLive})> list() async {
    try {
      final response = await _apiClient.dio.get(endpoint);
      final items = List<Map<String, dynamic>>.from(response.data as List);
      return (items: items, isLive: true);
    } on DioException {
      final cached = await _database.getReferenceRows(localTable, orderBy: 'name ASC');
      return (items: cached, isLive: false);
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _apiClient.dio.post(endpoint, data: data);
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await _apiClient.dio.put('$endpoint/$id', data: data);
  }

  Future<void> delete(int id) async {
    await _apiClient.dio.delete('$endpoint/$id');
  }
}
