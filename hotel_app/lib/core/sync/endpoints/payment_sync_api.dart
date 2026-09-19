import '../../config/api_endpoints.dart';
import '../../network/api_client.dart';

/// Wraps POST /api/sync/payments. Payments are effectively append-only,
/// but still go through the same uuid-upsert idempotency guarantee so a
/// retried request never double-records a payment.
class PaymentSyncApi {
  PaymentSyncApi(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> push(List<Map<String, dynamic>> records, String deviceId) async {
    if (records.isEmpty) return [];
    final response = await _apiClient.dio.post(
      ApiEndpoints.syncPayments,
      data: {'device_id': deviceId, 'records': records},
    );
    return List<Map<String, dynamic>>.from(
      (response.data as Map<String, dynamic>)['results'] as List,
    );
  }
}
