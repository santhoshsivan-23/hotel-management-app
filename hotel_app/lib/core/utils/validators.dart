/// Simple form-field validators. Each returns null when valid, or an
/// error message string for Flutter's TextFormField(validator: ...).
class Validators {
  Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? mobile(String? value) {
    if (value == null || value.trim().isEmpty) return 'Mobile number is required';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) return 'Enter a valid mobile number';
    return null;
  }

  static String? emailOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? positiveNumber(String? value, {String field = 'Value'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    final n = num.tryParse(value);
    if (n == null) return '$field must be a number';
    if (n < 0) return '$field cannot be negative';
    return null;
  }

  static String? positiveInteger(String? value, {String field = 'Value'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    final n = int.tryParse(value);
    if (n == null) return '$field must be a whole number';
    if (n <= 0) return '$field must be greater than zero';
    return null;
  }
}
