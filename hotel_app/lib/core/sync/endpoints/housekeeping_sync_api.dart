import '../../config/api_endpoints.dart';
import '../../network/api_client.dart';

class HousekeepingSyncApi {
  HousekeepingSyncApi(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> push(List<Map<String, dynamic>> records, String deviceId) async {
    if (records.isEmpty) return [];
    final response = await _apiClient.dio.post(
      ApiEndpoints.syncHousekeeping,
      data: {'device_id': deviceId, 'records': records},
    );
    return List<Map<String, dynamic>>.from(
      (response.data as Map<String, dynamic>)['results'] as List,
    );
  }
}
