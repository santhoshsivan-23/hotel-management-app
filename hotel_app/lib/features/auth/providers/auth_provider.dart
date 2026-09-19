import 'package:flutter/foundation.dart';
import '../../../core/auth/auth_service.dart';

/// Thin ChangeNotifier shell around AuthService so widgets can react to
/// login/logout without every screen holding its own copy of the session
/// state.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);
  final AuthService _authService;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _authService.currentUser;
  String? get role => _authService.role;
  bool get isLoggedIn => _authService.currentUser != null;

  Future<bool> restoreSession() => _authService.restoreSession();

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(username, password);

    _isLoading = false;
    _error = result.success ? null : result.message;
    notifyListeners();

    return result.success;
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}
