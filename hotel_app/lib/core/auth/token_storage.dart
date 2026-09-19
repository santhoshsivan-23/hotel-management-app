import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';

/// Wraps flutter_secure_storage for the JWT pair + a cached copy of the
/// logged-in user (name/username/role), so the app can restore a session
/// on cold start without waiting on a network call.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: AppConfig.secureAccessToken, value: accessToken);
    await _storage.write(key: AppConfig.secureRefreshToken, value: refreshToken);
  }

  Future<String?> get accessToken => _storage.read(key: AppConfig.secureAccessToken);
  Future<String?> get refreshToken => _storage.read(key: AppConfig.secureRefreshToken);

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: AppConfig.secureUserJson, value: jsonEncode(user));
  }

  Future<Map<String, dynamic>?> readUser() async {
    final raw = await _storage.read(key: AppConfig.secureUserJson);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clear() async {
    await _storage.delete(key: AppConfig.secureAccessToken);
    await _storage.delete(key: AppConfig.secureRefreshToken);
    await _storage.delete(key: AppConfig.secureUserJson);
  }

  Future<bool> get hasSession async => (await accessToken) != null;

  /// A random uuid generated once per install and persisted, used as the
  /// `device_id` on every sync push and on created_by_device server-side -
  /// simple, stable, and doesn't need any platform-specific device APIs.
  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: AppConfig.prefDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;

    final newId = 'device-${const Uuid().v4()}';
    await _storage.write(key: AppConfig.prefDeviceId, value: newId);
    return newId;
  }
}
