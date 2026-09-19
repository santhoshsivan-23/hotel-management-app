import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.round2', () {
    test('rounds to two decimal places', () {
      expect(CurrencyFormatter.round2(10.005), 10.01);
      expect(CurrencyFormatter.round2(10.004), 10.0);
      expect(CurrencyFormatter.round2(100), 100.0);
    });
  });

  group('CurrencyFormatter.format', () {
    test('formats a null amount as zero rather than throwing', () {
      expect(() => CurrencyFormatter.format(null), returnsNormally);
    });

    test('includes the rupee symbol for INR by default', () {
      expect(CurrencyFormatter.format(100), contains('₹'));
    });
  });
}
