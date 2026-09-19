import '../../config/api_endpoints.dart';
import '../../network/api_client.dart';

/// Wraps GET /api/sync/reference-data - the pull side of sync. Delta-pull
/// via `since`; the response's `server_time` becomes the new cursor,
/// stored by SyncManager via AppDatabase.setSyncCursor().
class ReferenceDataApi {
  ReferenceDataApi(this._apiClient);
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> pull(String since) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.syncReferenceData,
      queryParameters: {'since': since},
    );
    return response.data as Map<String, dynamic>;
  }
}
