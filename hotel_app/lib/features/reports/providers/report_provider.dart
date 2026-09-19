import 'package:flutter/foundation.dart';

/// Holds the shared date-range filter every report screen uses. Reports
/// require connectivity (they aggregate data across every device, not
/// just this one's local cache), so this provider only tracks UI filter
/// state - the actual fetching happens per-screen against the live API.
class ReportProvider extends ChangeNotifier {
  DateTime? fromDate;
  DateTime? toDate;

  void setRange(DateTime? from, DateTime? to) {
    fromDate = from;
    toDate = to;
    notifyListeners();
  }

  void clear() {
    fromDate = null;
    toDate = null;
    notifyListeners();
  }
}
