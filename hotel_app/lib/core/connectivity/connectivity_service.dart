import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../config/env.dart';
import 'connectivity_state.dart';

/// Wraps connectivity_plus (which only tells you "connected to a network")
/// with a real reachability check against the backend's /health endpoint,
/// because a Wi-Fi network with no internet still reports "connected".
///
/// This is deliberately the single source of truth the rest of the app
/// asks before showing/enabling the "Sync Now" control.
class ConnectivityService {
  ConnectivityService({required String healthCheckUrl, Dio? dio})
      : _healthCheckUrl = healthCheckUrl,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 4),
                headers: Map<String, dynamic>.from(Env.apiHeaders),
              ),
            );

  final String _healthCheckUrl;
  final Dio _dio;

  final _stateController = StreamController<ConnectivityState>.broadcast();
  Stream<ConnectivityState> get stream => _stateController.stream;

  ConnectivityState _lastState = ConnectivityState.offline;
  ConnectivityState get lastState => _lastState;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void start() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) async {
      await _evaluate(results);
    });
    // Fire an initial check immediately rather than waiting for the first change event.
    Connectivity().checkConnectivity().then(_evaluate);
  }

  void dispose() {
    _subscription?.cancel();
    _stateController.close();
  }

  Future<void> _evaluate(List<ConnectivityResult> results) async {
    final hasAnyNetwork = results.any((r) => r != ConnectivityResult.none);
    if (!hasAnyNetwork) {
      _emit(ConnectivityState.offline);
      return;
    }

    _emit(ConnectivityState.checking);
    final reachable = await isTrulyOnline();
    _emit(reachable ? ConnectivityState.online : ConnectivityState.offline);
  }

  void _emit(ConnectivityState state) {
    _lastState = state;
    _stateController.add(state);
  }

  /// One-shot reachability check - used both by the background listener
  /// above and directly by SyncManager right before a sync attempt, so
  /// there's never a stale "online" badge that then fails on tap.
  Future<bool> isTrulyOnline() async {
    try {
      final response = await _dio.get(_healthCheckUrl);
      return response.statusCode != null && response.statusCode! < 500;
    } catch (_) {
      return false;
    }
  }

  /// Manually re-check right now (e.g. pull-to-refresh on the sync badge).
  Future<ConnectivityState> refresh() async {
    final results = await Connectivity().checkConnectivity();
    await _evaluate(results);
    return _lastState;
  }
}
