import '../../config/api_endpoints.dart';
import '../../network/api_client.dart';

/// Wraps POST /api/sync/food-orders. Requires booking_uuid and guest_uuid
/// to already exist server-side, so bookings sync before food orders.
class FoodOrderSyncApi {
  FoodOrderSyncApi(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> push(List<Map<String, dynamic>> records, String deviceId) async {
    if (records.isEmpty) return [];
    final response = await _apiClient.dio.post(
      ApiEndpoints.syncFoodOrders,
      data: {'device_id': deviceId, 'records': records},
    );
    return List<Map<String, dynamic>>.from(
      (response.data as Map<String, dynamic>)['results'] as List,
    );
  }
}
