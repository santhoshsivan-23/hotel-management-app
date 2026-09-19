import 'package:dio/dio.dart';
import '../config/api_endpoints.dart';
import '../network/api_client.dart';
import 'token_storage.dart';

class AuthResult {
  AuthResult({required this.success, this.message});
  final bool success;
  final String? message;
}

/// Login/refresh/logout + the currently-known user, backed by TokenStorage
/// so a session survives app restarts without a network round trip.
class AuthService {
  AuthService({required ApiClient apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient,
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;

  String? get role => _currentUser?['role'] as String?;

  Future<bool> restoreSession() async {
    final user = await _tokenStorage.readUser();
    final hasToken = await _tokenStorage.hasSession;
    if (user != null && hasToken) {
      _currentUser = user;
      return true;
    }
    return false;
  }

  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {'username': username, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      await _tokenStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      _currentUser = Map<String, dynamic>.from(data['user'] as Map);
      await _tokenStorage.saveUser(_currentUser!);

      return AuthResult(success: true);
    } on DioException catch (e) {
      final message = (e.response?.data is Map)
          ? (e.response?.data['message'] as String? ?? 'Login failed')
          : 'Could not reach the server';
      return AuthResult(success: false, message: message);
    } catch (e) {
      return AuthResult(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<bool> tryRefresh() async {
    final refreshToken = await _tokenStorage.refreshToken;
    if (refreshToken == null) return false;

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      await _tokenStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _tokenStorage.clear();
  }
}
