import 'package:flutter/foundation.dart';
import '../../../core/db/app_database.dart';
import '../../reservations/data/models/booking_model.dart';
import '../../reservations/data/repositories/booking_repository.dart';

/// A booking paired with its real running-bill balance (room + food +
/// service charges, tax, minus payments) - not just grandTotal minus
/// advance, which would miss anything added after check-in.
class OutstandingEntry {
  OutstandingEntry(this.booking, this.balance);
  final BookingModel booking;
  final double balance;
}

/// Backs the Payments & Billing landing screen: every booking with a
/// balance still owed, computed locally exactly like the backend's
/// Outstanding Report (see report.service.js#outstandingReport), but
/// entirely from the offline cache.
class BillingProvider extends ChangeNotifier {
  BillingProvider(this._database) : _bookingRepository = BookingRepository(_database);

  final AppDatabase _database;
  final BookingRepository _bookingRepository;

  List<OutstandingEntry> _outstanding = [];
  bool _loading = false;

  List<OutstandingEntry> get outstanding => _outstanding;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final active = [
      ...await _bookingRepository.findAll(status: 'CONFIRMED'),
      ...await _bookingRepository.findAll(status: 'CHECKED_IN'),
      ...await _bookingRepository.findAll(status: 'CHECKED_OUT'),
    ];

    final results = <OutstandingEntry>[];
    for (final booking in active) {
      final bill = await _bookingRepository.runningBill(booking);
      final balance = bill['balance'] ?? 0;
      if (balance > 0) results.add(OutstandingEntry(booking, balance));
    }

    _outstanding = results;
    _loading = false;
    notifyListeners();
  }
}
