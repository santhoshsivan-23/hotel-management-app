import 'package:dio/dio.dart';
import '../../config/api_endpoints.dart';
import '../../network/api_client.dart';

/// Thin wrapper around POST /api/sync/guests. Every endpoint wrapper in
/// this folder follows the same shape: take the pending local rows
/// (already shaped to match what the backend controller expects), post
/// them as one batch, and return the per-record {uuid, status, error?}
/// results so SyncManager can update each local row individually.
class GuestSyncApi {
  GuestSyncApi(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> push(List<Map<String, dynamic>> records, String deviceId) async {
    if (records.isEmpty) return [];
    final response = await _apiClient.dio.post(
      ApiEndpoints.syncGuests,
      data: {'device_id': deviceId, 'records': records},
    );
    return List<Map<String, dynamic>>.from(
      (response.data as Map<String, dynamic>)['results'] as List,
    );
  }
}
