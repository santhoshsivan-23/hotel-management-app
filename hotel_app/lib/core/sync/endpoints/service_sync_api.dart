import '../../config/api_endpoints.dart';
import '../../network/api_client.dart';

/// Wraps POST /api/sync/service-requests.
class ServiceSyncApi {
  ServiceSyncApi(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> push(List<Map<String, dynamic>> records, String deviceId) async {
    if (records.isEmpty) return [];
    final response = await _apiClient.dio.post(
      ApiEndpoints.syncServiceRequests,
      data: {'device_id': deviceId, 'records': records},
    );
    return List<Map<String, dynamic>>.from(
      (response.data as Map<String, dynamic>)['results'] as List,
    );
  }
}
