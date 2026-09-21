import '../../../../core/db/app_database.dart';
import '../../../../core/db/daos/booking_dao.dart';
import '../../../../core/db/daos/payment_dao.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  PaymentRepository(AppDatabase database)
      : _dao = PaymentDao(database),
        _database = database;
  final PaymentDao _dao;
  final AppDatabase _database;

  Future<List<PaymentModel>> findByBooking(String bookingUuid) async {
    final rows = await _dao.findByBooking(bookingUuid);
    return rows.map(PaymentModel.fromMap).toList();
  }

  Future<PaymentModel> create({
    required String bookingUuid,
    required double amount,
    required String method,
    String? referenceNo,
    String? deviceId,
  }) async {
    final bookingRow = await BookingDao(_database).findByUuid(bookingUuid);
    if (bookingRow != null && bookingRow['status'] == 'CHECKED_OUT') {
      throw StateError('Cannot add payments to a checked-out stay');
    }

    final now = DateTime.now().toUtc();
    final payment = PaymentModel(
      uuid: UuidGenerator.generate(),
      bookingUuid: bookingUuid,
      amount: amount,
      method: method,
      referenceNo: referenceNo,
      paidAt: now,
      syncStatus: 'PENDING',
      createdAt: now,
      updatedAt: now,
    );

    final row = payment.toMap();
    if (deviceId != null) row['device_id'] = deviceId;
    await _dao.insert(row);
    return payment;
  }

  Future<double> totalPaid(String bookingUuid) => _dao.totalPaid(bookingUuid);
}
