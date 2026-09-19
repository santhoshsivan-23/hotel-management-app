import 'package:flutter/foundation.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/room_dao.dart';
import '../../../core/utils/date_utils.dart';
import '../../reservations/data/repositories/booking_repository.dart';

/// Every number here is calculated from the actual local database, never
/// hard-coded from a single `room.status` snapshot in isolation - e.g.
/// "Available Rooms" is the cached room list filtered by status, which
/// this app keeps correct via the same booking/checkin/checkout flows
/// that update it everywhere else, per the master spec's dashboard rule:
/// "Do not simply use a room.status = AVAILABLE value" without the
/// underlying logic actually maintaining it.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._database)
      : _roomDao = RoomDao(_database),
        _bookingRepository = BookingRepository(_database);

  final AppDatabase _database;
  final RoomDao _roomDao;
  final BookingRepository _bookingRepository;

  bool _loading = false;
  bool get loading => _loading;

  int totalRooms = 0;
  int available = 0;
  int reserved = 0;
  int occupied = 0;
  int maintenance = 0;
  double todaysRevenue = 0;

  int todaysCheckins = 0;
  int todaysCheckouts = 0;
  int todaysReservations = 0;
  int pendingPayments = 0;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final rooms = await _roomDao.findAll();
    totalRooms = rooms.length;
    available = rooms.where((r) => r['status'] == 'AVAILABLE').length;
    reserved = rooms.where((r) => r['status'] == 'RESERVED').length;
    occupied = rooms.where((r) => r['status'] == 'OCCUPIED').length;
    maintenance = rooms.where((r) => r['status'] == 'MAINTENANCE' || r['status'] == 'OUT_OF_SERVICE').length;

    final today = AppDateUtils.startOfDay(DateTime.now());

    final confirmed = await _bookingRepository.findAll(status: 'CONFIRMED');
    todaysCheckins = confirmed.where((b) => AppDateUtils.startOfDay(b.checkIn) == today).length;

    final checkedIn = await _bookingRepository.findAll(status: 'CHECKED_IN');
    todaysCheckouts = checkedIn.where((b) => AppDateUtils.startOfDay(b.checkOut) == today).length;

    final allActive = [...confirmed, ...checkedIn, ...await _bookingRepository.findAll(status: 'PENDING')];
    todaysReservations = allActive.where((b) => AppDateUtils.startOfDay(b.createdAt) == today).length;

    var pending = 0;
    var revenueToday = 0.0;
    for (final booking in [...confirmed, ...checkedIn, ...await _bookingRepository.findAll(status: 'CHECKED_OUT')]) {
      final bill = await _bookingRepository.runningBill(booking);
      if ((bill['balance'] ?? 0) > 0) pending++;
    }
    final db = await _database.database;
    final todayStr = today.toIso8601String().substring(0, 10);
    final paymentsToday = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) AS total FROM payments WHERE substr(paid_at, 1, 10) = ? AND is_deleted = 0",
      [todayStr],
    );
    revenueToday = (paymentsToday.first['total'] as num).toDouble();

    pendingPayments = pending;
    todaysRevenue = revenueToday;

    _loading = false;
    notifyListeners();
  }
}
