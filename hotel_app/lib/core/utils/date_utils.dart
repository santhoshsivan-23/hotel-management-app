import 'package:intl/intl.dart';
import '../config/app_config.dart';

/// Date helpers shared across the booking/reservation flow. Mirrors the
/// equivalent helpers on the backend (src/utils/dateHelpers.js) so both
/// sides agree on nights-between and overlap calculations.
class AppDateUtils {
  AppDateUtils._();

  static String toApiDate(DateTime date) {
    return DateFormat(AppConfig.apiDateFormat).format(date);
  }

  static String toApiDateTime(DateTime date) {
    return DateFormat(AppConfig.apiDateTimeFormat).format(date.toUtc());
  }

  static String formatDisplayDate(DateTime date) {
    return DateFormat(AppConfig.displayDateFormat).format(date);
  }

  static String formatDisplayDateTime(DateTime date) {
    return DateFormat(AppConfig.displayDateTimeFormat).format(date);
  }

  static DateTime? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Number of nights between two dates, minimum 1 - matches the backend's
  /// nightsBetween() so pricing computed offline matches what the server
  /// recomputes on sync.
  static int nightsBetween(DateTime checkIn, DateTime checkOut) {
    final nights = checkOut.difference(checkIn).inHours / 24;
    return nights.round().clamp(1, 3650);
  }

  /// Overlap rule used by the local "is this room available" check before
  /// a booking is even attempted: existing.start < new.end AND
  /// existing.end > new.start.
  static bool rangesOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
  }

  static DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  static DateTime nowUtc() => DateTime.now().toUtc();
}
