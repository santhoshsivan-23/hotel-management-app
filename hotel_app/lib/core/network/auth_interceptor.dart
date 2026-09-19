import 'package:dio/dio.dart';
import '../auth/token_storage.dart';

/// Attaches the stored JWT to every outgoing request. Token refresh-on-401
/// is handled one level up in AuthService (it owns the Dio instance and
/// can retry cleanly); this interceptor's job is just to keep every
/// request authenticated by default.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);
  final TokenStorage _tokenStorage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
