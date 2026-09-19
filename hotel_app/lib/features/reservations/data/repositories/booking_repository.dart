import '../../../../core/db/app_database.dart';
import '../../../../core/db/daos/booking_dao.dart';
import '../../../../core/db/tables/taxes_table.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../food_orders/data/repositories/food_order_repository.dart';
import '../../../payments_billing/data/repositories/payment_repository.dart';
import '../../../room_services/data/repositories/service_request_repository.dart';
import '../models/booking_model.dart';

/// Bookings are fully offline-capable. Every read/write here is local;
/// SyncManager is the only thing that later pushes a booking to the
/// server (see sync_manager.dart's _syncBookings()).
class BookingRepository {
  BookingRepository(this._database) : _dao = BookingDao(_database);

  final AppDatabase _database;
  final BookingDao _dao;

  Future<List<BookingModel>> findAll({String? status}) async {
    final rows = await _dao.findAll(status: status);
    return rows.map(BookingModel.fromMap).toList();
  }

  Future<BookingModel?> findByUuid(String uuid) async {
    final row = await _dao.findByUuid(uuid);
    return row == null ? null : BookingModel.fromMap(row);
  }

  /// Mirrors booking.service.js#calculatePricing: nights x rate, minus
  /// discount, plus the sum of active ROOM/ALL tax percentages from the
  /// local taxes cache.
  Future<PricingBreakdown> calculatePricing({
    required double roomRate,
    required DateTime checkIn,
    required DateTime checkOut,
    double discount = 0,
  }) async {
    final nights = AppDateUtils.nightsBetween(checkIn, checkOut);
    final roomTotal = CurrencyFormatter.round2(roomRate * nights);
    final subtotal = CurrencyFormatter.round2(roomTotal - discount);

    final taxRows = await _database.getReferenceRows(
      TaxesTable.tableName,
      where: "active = 1 AND (applicable_to = 'ROOM' OR applicable_to = 'ALL')",
    );
    final taxPercent = taxRows.fold<double>(0, (sum, t) => sum + (t['percentage'] as num).toDouble());
    final taxAmount = CurrencyFormatter.round2(subtotal * taxPercent / 100);
    final grandTotal = CurrencyFormatter.round2(subtotal + taxAmount);

    return PricingBreakdown(
      nights: nights,
      roomTotal: roomTotal,
      discount: discount,
      taxAmount: taxAmount,
      taxPercent: taxPercent,
      grandTotal: grandTotal,
    );
  }

  /// Local overlap guard - the same rule the backend enforces again on
  /// sync (bookings.model.js#hasOverlap / the sync controller's re-check),
  /// so a conflict is caught immediately rather than only discovered when
  /// this device eventually gets signal.
  Future<bool> isRoomAvailable({
    required int roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? excludeUuid,
  }) async {
    final overlap = await _dao.hasOverlap(
      roomId: roomId,
      checkInIso: checkIn.toUtc().toIso8601String(),
      checkOutIso: checkOut.toUtc().toIso8601String(),
      excludeUuid: excludeUuid,
    );
    return !overlap;
  }

  Future<BookingModel> create({
    required String guestUuid,
    required int roomId,
    required double roomRate,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
    double discount = 0,
    double advancePaid = 0,
  }) async {
    final available = await isRoomAvailable(roomId: roomId, checkIn: checkIn, checkOut: checkOut);
    if (!available) {
      throw StateError('This room is no longer available for the selected dates');
    }

    final pricing = await calculatePricing(roomRate: roomRate, checkIn: checkIn, checkOut: checkOut, discount: discount);
    final now = DateTime.now().toUtc();

    final booking = BookingModel(
      uuid: UuidGenerator.generate(),
      bookingNumber: null, // assigned by the server on sync; shown locally as "Pending sync"
      guestUuid: guestUuid,
      roomId: roomId,
      checkIn: checkIn,
      checkOut: checkOut,
      adults: adults,
      children: children,
      roomRate: roomRate,
      nights: pricing.nights,
      roomTotal: pricing.roomTotal,
      discount: pricing.discount,
      taxAmount: pricing.taxAmount,
      grandTotal: pricing.grandTotal,
      advancePaid: advancePaid,
      status: 'CONFIRMED',
      syncStatus: 'PENDING',
      createdAt: now,
      updatedAt: now,
    );

    await _dao.insert(booking.toMap());
    return booking;
  }

  Future<void> updateStatus(String uuid, String status) => _dao.updateStatus(uuid, status);

  /// Optimistically updates the local rooms cache immediately, rather than
  /// waiting for a round-trip sync - the whole point of offline-first is
  /// that local reads (the dashboard's room counts, the room grid) reflect
  /// reality right away. The backend's sync/bookings handler now applies
  /// the exact same room-status transitions once this booking change
  /// syncs up, so both sides agree once online again.
  Future<void> _setRoomStatus(int roomId, String status) async {
    final db = await _database.database;
    await db.update('rooms', {'status': status}, where: 'id = ?', whereArgs: [roomId]);
  }

  Future<void> cancel(String uuid) async {
    final booking = await findByUuid(uuid);
    await _dao.updateStatus(uuid, 'CANCELLED');
    if (booking != null) await _setRoomStatus(booking.roomId, 'AVAILABLE');
  }

  Future<void> checkin(String uuid) async {
    final booking = await findByUuid(uuid);
    await _dao.updateStatus(uuid, 'CHECKED_IN');
    if (booking != null) await _setRoomStatus(booking.roomId, 'OCCUPIED');
  }

  Future<void> checkout(String uuid) => _dao.updateStatus(uuid, 'CHECKED_OUT');

  Future<void> changeRoom(String uuid, int newRoomId) async {
    final booking = await findByUuid(uuid);
    if (booking == null) return;

    final available = await isRoomAvailable(
      roomId: newRoomId,
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
      excludeUuid: uuid,
    );
    if (!available) {
      throw StateError('That room is not available for these dates');
    }

    await _dao.update(uuid, {'room_id': newRoomId});

    final newRoomStatus = booking.status == 'CHECKED_IN' ? 'OCCUPIED' : 'RESERVED';
    await _setRoomStatus(newRoomId, newRoomStatus);
    await _setRoomStatus(booking.roomId, 'AVAILABLE');
  }

  Future<void> extendStay(String uuid, BookingModel current, DateTime newCheckOut) async {
    final pricing = await calculatePricing(
      roomRate: current.roomRate,
      checkIn: current.checkIn,
      checkOut: newCheckOut,
      discount: current.discount,
    );
    await _dao.update(uuid, {
      'check_out': newCheckOut.toUtc().toIso8601String(),
      'nights': pricing.nights,
      'room_total': pricing.roomTotal,
      'tax_amount': pricing.taxAmount,
      'grand_total': pricing.grandTotal,
    });
  }

  /// Running bill - room charges + food + services, minus payments made so
  /// far. Mirrors invoice.service.js#buildInvoice, computed entirely from
  /// the local cache so it works offline.
  Future<Map<String, double>> runningBill(BookingModel booking) async {
    final foodTotal = await FoodOrderRepository(_database).totalForBooking(booking.uuid);
    final serviceTotal = await ServiceRequestRepository(_database).totalForBooking(booking.uuid);
    final paidTotal = await PaymentRepository(_database).totalPaid(booking.uuid);

    final subtotal = CurrencyFormatter.round2(booking.roomTotal + foodTotal + serviceTotal - booking.discount);
    final grandTotal = CurrencyFormatter.round2(subtotal + booking.taxAmount);
    final balance = CurrencyFormatter.round2(grandTotal - paidTotal);

    return {
      'roomCharges': booking.roomTotal,
      'foodCharges': foodTotal,
      'serviceCharges': serviceTotal,
      'discount': booking.discount,
      'tax': booking.taxAmount,
      'grandTotal': grandTotal,
      'paidAmount': paidTotal,
      'balance': balance,
    };
  }
}
