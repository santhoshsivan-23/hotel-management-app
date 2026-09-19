import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/token_storage.dart';
import 'core/connectivity/connectivity_service.dart';
import 'core/db/app_database.dart';
import 'core/network/api_client.dart';
import 'core/sync/endpoints/booking_sync_api.dart';
import 'core/sync/endpoints/food_order_sync_api.dart';
import 'core/sync/endpoints/guest_sync_api.dart';
import 'core/sync/endpoints/housekeeping_sync_api.dart';
import 'core/sync/endpoints/maintenance_sync_api.dart';
import 'core/sync/endpoints/payment_sync_api.dart';
import 'core/sync/endpoints/reference_data_api.dart';
import 'core/sync/endpoints/service_sync_api.dart';
import 'core/sync/sync_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Wire the whole dependency graph once, here, and hand it down through
  // app.dart's MultiProvider. Nothing below this point talks to the
  // network or the database except through these shared instances.
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final authService = AuthService(apiClient: apiClient, tokenStorage: tokenStorage);

  // Wired here (not in ApiClient's constructor) because AuthService itself
  // depends on ApiClient - this closes the loop so an expired access token
  // gets one automatic refresh-and-retry instead of just failing.
  apiClient.onUnauthorized = authService.tryRefresh;

  final connectivityService = ConnectivityService(healthCheckUrl: apiClient.healthCheckUrl)..start();

  final database = AppDatabase.instance;
  final deviceId = await tokenStorage.getOrCreateDeviceId();

  final syncManager = SyncManager(
    connectivityService: connectivityService,
    database: database,
    deviceId: deviceId,
    guestApi: GuestSyncApi(apiClient),
    bookingApi: BookingSyncApi(apiClient),
    foodOrderApi: FoodOrderSyncApi(apiClient),
    serviceApi: ServiceSyncApi(apiClient),
    paymentApi: PaymentSyncApi(apiClient),
    maintenanceApi: MaintenanceSyncApi(apiClient),
    housekeepingApi: HousekeepingSyncApi(apiClient),
    referenceDataApi: ReferenceDataApi(apiClient),
  );

  runApp(HotelApp(
    apiClient: apiClient,
    authService: authService,
    connectivityService: connectivityService,
    database: database,
    syncManager: syncManager,
  ));
}
