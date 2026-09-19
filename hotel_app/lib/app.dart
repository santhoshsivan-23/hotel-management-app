import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/auth/auth_service.dart';
import 'core/auth/permission_service.dart';
import 'core/connectivity/connectivity_service.dart';
import 'core/db/app_database.dart';
import 'core/network/api_client.dart';
import 'core/sync/sync_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'routes/app_router.dart';

/// Root widget. Everything a feature might need that ISN'T specific to
/// just that feature (auth state, connectivity, the sync manager, the
/// database, the api client, permission checks) is provided once here,
/// above the router, so any screen can reach it with context.watch/read.
class HotelApp extends StatelessWidget {
  const HotelApp({
    super.key,
    required this.apiClient,
    required this.authService,
    required this.connectivityService,
    required this.database,
    required this.syncManager,
  });

  final ApiClient apiClient;
  final AuthService authService;
  final ConnectivityService connectivityService;
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<AppDatabase>.value(value: database),
        Provider<ConnectivityService>.value(value: connectivityService),
        Provider<SyncManager>.value(value: syncManager),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider(authService)),
        ProxyProvider<AuthProvider, PermissionService>(
          update: (_, __, ___) => PermissionService(authService),
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Decides the first screen: restore a saved session and go straight to
/// the dashboard (works even offline - session restore reads local secure
/// storage only), or fall back to the login screen.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checked = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final restored = await context.read<AuthProvider>().restoreSession();
    if (!mounted) return;
    setState(() {
      _loggedIn = restored;
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _loggedIn ? const DashboardScreen() : const LoginScreen();
  }
}
