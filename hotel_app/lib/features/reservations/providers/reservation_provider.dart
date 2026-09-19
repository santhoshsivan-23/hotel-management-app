import 'package:flutter/foundation.dart';
import '../../../core/db/app_database.dart';
import '../data/models/booking_model.dart';
import '../data/repositories/booking_repository.dart';

class ReservationProvider extends ChangeNotifier {
  ReservationProvider(AppDatabase database) : _repository = BookingRepository(database);

  final BookingRepository _repository;
  BookingRepository get repository => _repository;

  List<BookingModel> _bookings = [];
  bool _loading = false;
  String? _statusFilter;

  List<BookingModel> get bookings => _bookings;
  bool get loading => _loading;
  String? get statusFilter => _statusFilter;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _bookings = await _repository.findAll(status: _statusFilter);
    _loading = false;
    notifyListeners();
  }

  Future<void> setStatusFilter(String? status) async {
    _statusFilter = status;
    await load();
  }
}
