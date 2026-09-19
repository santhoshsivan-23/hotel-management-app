import '../../../../core/db/app_database.dart';
import '../../../../core/db/daos/service_request_dao.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../models/service_request_model.dart';

class ServiceRequestRepository {
  ServiceRequestRepository(AppDatabase database) : _dao = ServiceRequestDao(database);
  final ServiceRequestDao _dao;

  Future<List<ServiceRequestModel>> findAll({String? status, String? bookingUuid}) async {
    final rows = await _dao.findAll(status: status, bookingUuid: bookingUuid);
    return rows.map(ServiceRequestModel.fromMap).toList();
  }

  Future<ServiceRequestModel> create({
    required String bookingUuid,
    required int roomId,
    required String guestUuid,
    required int serviceTypeId,
    required int quantity,
    required double unitPrice,
    String? notes,
    String? deviceId,
  }) async {
    final now = DateTime.now().toUtc();
    final request = ServiceRequestModel(
      uuid: UuidGenerator.generate(),
      bookingUuid: bookingUuid,
      roomId: roomId,
      guestUuid: guestUuid,
      serviceTypeId: serviceTypeId,
      quantity: quantity,
      amount: unitPrice * quantity,
      status: 'REQUESTED',
      notes: notes,
      syncStatus: 'PENDING',
      createdAt: now,
      updatedAt: now,
    );

    final row = request.toMap();
    if (deviceId != null) row['device_id'] = deviceId;
    await _dao.insert(row);
    return request;
  }

  Future<void> updateStatus(String uuid, String status) => _dao.updateStatus(uuid, status);

  Future<double> totalForBooking(String bookingUuid) => _dao.totalForBooking(bookingUuid);
}
