import '../../config/api_endpoints.dart';
import '../../network/api_client.dart';

/// Wraps POST /api/sync/bookings. The backend resolves `guest_uuid` to a
/// real guest_id, so guests must be pushed before bookings - see
/// SyncManager.syncAll() for the enforced ordering.
class BookingSyncApi {
  BookingSyncApi(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> push(List<Map<String, dynamic>> records, String deviceId) async {
    if (records.isEmpty) return [];
    final response = await _apiClient.dio.post(
      ApiEndpoints.syncBookings,
      data: {'device_id': deviceId, 'records': records},
    );
    return List<Map<String, dynamic>>.from(
      (response.data as Map<String, dynamic>)['results'] as List,
    );
  }

  /// Pulls other devices' active bookings so this device's local
  /// availability search stays accurate even for rooms booked elsewhere.
  /// Lives under the reference-data sync routes on the backend (see
  /// referenceData.controller.js#pullBookings), not under /sync/bookings
  /// itself (that path is the POST-only push endpoint).
  Future<List<Map<String, dynamic>>> pullActiveBookings(String since) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.syncActiveBookings,
      queryParameters: {'since': since},
    );
    return List<Map<String, dynamic>>.from(
      (response.data as Map<String, dynamic>)['bookings'] as List,
    );
  }
}
