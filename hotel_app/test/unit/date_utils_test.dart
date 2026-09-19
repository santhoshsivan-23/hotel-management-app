import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils.nightsBetween', () {
    test('computes whole nights for a simple range', () {
      final checkIn = DateTime(2026, 9, 10);
      final checkOut = DateTime(2026, 9, 13);
      expect(AppDateUtils.nightsBetween(checkIn, checkOut), 3);
    });

    test('never returns less than 1 night', () {
      final sameDay = DateTime(2026, 9, 10, 10, 0);
      final laterSameDay = DateTime(2026, 9, 10, 14, 0);
      expect(AppDateUtils.nightsBetween(sameDay, laterSameDay), 1);
    });
  });

  group('AppDateUtils.rangesOverlap', () {
    test('detects an overlapping range', () {
      final aStart = DateTime(2026, 9, 10);
      final aEnd = DateTime(2026, 9, 13);
      final bStart = DateTime(2026, 9, 12);
      final bEnd = DateTime(2026, 9, 15);
      expect(AppDateUtils.rangesOverlap(aStart, aEnd, bStart, bEnd), isTrue);
    });

    test('back-to-back stays (checkout day == checkin day) do not overlap', () {
      final aStart = DateTime(2026, 9, 10);
      final aEnd = DateTime(2026, 9, 13);
      final bStart = DateTime(2026, 9, 13);
      final bEnd = DateTime(2026, 9, 15);
      expect(AppDateUtils.rangesOverlap(aStart, aEnd, bStart, bEnd), isFalse);
    });

    test('a range fully before another does not overlap', () {
      final aStart = DateTime(2026, 9, 10);
      final aEnd = DateTime(2026, 9, 13);
      final bStart = DateTime(2026, 9, 1);
      final bEnd = DateTime(2026, 9, 10);
      expect(AppDateUtils.rangesOverlap(aStart, aEnd, bStart, bEnd), isFalse);
    });
  });
}
