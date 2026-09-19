import 'package:intl/intl.dart';
import '../config/app_config.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(num? amount, {String currency = AppConfig.defaultCurrency}) {
    final value = amount ?? 0;
    final symbol = _symbolFor(currency);
    final formatter = NumberFormat.currency(
      locale: AppConfig.defaultLocale,
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  static String _symbolFor(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '$currency ';
    }
  }

  static double round2(num value) => (value * 100).round() / 100;
}
