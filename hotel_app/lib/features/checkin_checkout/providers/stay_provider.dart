import 'package:flutter/foundation.dart';
import '../../../core/db/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../reservations/data/models/booking_model.dart';
import '../../reservations/data/repositories/booking_repository.dart';

/// Backs the three Check-in/Check-out tabs: Today's Arrivals, Active
/// Stays, Today's Departures - all computed locally from the cached
/// bookings table, so front-desk staff can see today's board with zero
/// connectivity.
class StayProvider extends ChangeNotifier {
  StayProvider(AppDatabase database) : _repository = BookingRepository(database);

  final BookingRepository _repository;
  BookingRepository get repository => _repository;

  List<BookingModel> _arrivals = [];
  List<BookingModel> _activeStays = [];
  List<BookingModel> _departures = [];
  bool _loading = false;

  List<BookingModel> get arrivals => _arrivals;
  List<BookingModel> get activeStays => _activeStays;
  List<BookingModel> get departures => _departures;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final today = AppDateUtils.startOfDay(DateTime.now());
    final confirmed = await _repository.findAll(status: 'CONFIRMED');
    final checkedIn = await _repository.findAll(status: 'CHECKED_IN');

    _arrivals = confirmed.where((b) => AppDateUtils.startOfDay(b.checkIn) == today).toList();
    _activeStays = checkedIn;
    _departures = checkedIn.where((b) => AppDateUtils.startOfDay(b.checkOut) == today).toList();

    _loading = false;
    notifyListeners();
  }
}
