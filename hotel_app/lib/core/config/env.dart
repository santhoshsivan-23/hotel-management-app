/// Build-time environment configuration.
///
/// Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:5000/api
///   flutter build apk --dart-define=API_BASE_URL=https://hotel.example.com/api
///
/// Using --dart-define keeps this dependency-free (no asset loading, no
/// .env parsing package) while still letting each environment point at a
/// different backend without changing code.
class Env {
  Env._();

  static const String baseUrl = 'https://couch-durably-mankind.ngrok-free.dev';

  /// Headers that must accompany every request to [baseUrl].
  ///
  /// While [baseUrl] points at an ngrok free-tier tunnel, ngrok answers
  /// browser-originated requests with an HTML warning page (ERR_NGROK_6024)
  /// instead of proxying them. That page carries no `Access-Control-Allow-Origin`
  /// header, so the browser reports it as a CORS failure even though the
  /// backend itself allows all origins. `ngrok-skip-browser-warning` (any
  /// value) suppresses the interstitial.
  static const Map<String, String> apiHeaders = {
    'ngrok-skip-browser-warning': 'true',
  };

  /// [apiHeaders] plus a JSON content type, for requests that send a body.
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '$baseUrl/api',
  );

  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
}
