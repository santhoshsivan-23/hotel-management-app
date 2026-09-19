/// App-wide constants that aren't secrets and aren't per-environment (those
/// live in env.dart instead).
class AppConfig {
  AppConfig._();

  static const String appName = 'Hotel Manager';

  /// Local storage keys
  static const String prefDeviceId = 'device_id';
  static const String secureAccessToken = 'access_token';
  static const String secureRefreshToken = 'refresh_token';
  static const String secureUserJson = 'current_user';

  /// How many records go in a single sync push request per table. Keeps
  /// individual requests small on slow hotel Wi-Fi/mobile connections.
  static const int syncBatchSize = 50;

  /// Default currency + locale used when formatting money.
  static const String defaultCurrency = 'INR';
  static const String defaultLocale = 'en_IN';

  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayDateTimeFormat = 'dd MMM yyyy, hh:mm a';
}
