import 'package:dio/dio.dart';
import '../config/env.dart';
import '../auth/token_storage.dart';
import 'auth_interceptor.dart';

/// Single Dio instance the whole app shares - every repository and every
/// sync endpoint wrapper goes through this, so base URL, timeouts, and
/// auth headers are configured in exactly one place.
class ApiClient {
  ApiClient({TokenStorage? tokenStorage}) : _tokenStorage = tokenStorage ?? TokenStorage() {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: Map<String, dynamic>.from(Env.jsonHeaders),
      ),
    );
    dio.interceptors.add(AuthInterceptor(_tokenStorage));
    dio.interceptors.add(InterceptorsWrapper(onError: _handleError));
  }

  final TokenStorage _tokenStorage;
  late final Dio dio;

  /// Wired up in main.dart, after AuthService exists (ApiClient is built
  /// first, so this can't just be a constructor dependency - AuthService
  /// itself depends on ApiClient). Should attempt a token refresh and
  /// return true only if it succeeded.
  Future<bool> Function()? onUnauthorized;

  Future<void> _handleError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['retriedAfterRefresh'] == true;

    if (!isUnauthorized || alreadyRetried || onUnauthorized == null) {
      return handler.next(err);
    }

    final refreshed = await onUnauthorized!();
    if (!refreshed) {
      return handler.next(err);
    }

    try {
      final newToken = await _tokenStorage.accessToken;
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newToken'
        ..extra['retriedAfterRefresh'] = true;
      final response = await dio.fetch(retryOptions);
      return handler.resolve(response);
    } catch (_) {
      return handler.next(err);
    }
  }

  /// The backend's lightweight reachability probe - used by
  /// ConnectivityService, not routed through /api since /health sits
  /// outside the API prefix.
  String get healthCheckUrl {
    final base = Env.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base/health';
  }
}
