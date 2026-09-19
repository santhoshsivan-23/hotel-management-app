import 'package:sqflite/sqflite.dart';

import '../connectivity/connectivity_service.dart';
import '../db/app_database.dart';
import '../db/daos/guest_dao.dart';
import '../db/daos/booking_dao.dart';
import '../db/daos/food_order_dao.dart';
import '../db/daos/service_request_dao.dart';
import '../db/daos/payment_dao.dart';
import '../db/daos/maintenance_dao.dart';
import '../db/daos/housekeeping_dao.dart';
import '../db/tables/guests_table.dart';
import '../db/tables/bookings_table.dart';
import '../db/tables/food_orders_table.dart';
import '../db/tables/service_requests_table.dart';
import '../db/tables/payments_table.dart';
import '../db/tables/maintenance_table.dart';
import '../db/tables/housekeeping_table.dart';
import '../db/tables/rooms_table.dart';
import '../db/tables/room_types_table.dart';
import '../db/tables/amenities_table.dart';
import '../db/tables/taxes_table.dart';
import '../db/tables/service_types_table.dart';
import '../db/tables/payment_methods_table.dart';
import '../db/tables/hotel_settings_table.dart';
import 'endpoints/guest_sync_api.dart';
import 'endpoints/booking_sync_api.dart';
import 'endpoints/food_order_sync_api.dart';
import 'endpoints/service_sync_api.dart';
import 'endpoints/payment_sync_api.dart';
import 'endpoints/maintenance_sync_api.dart';
import 'endpoints/housekeeping_sync_api.dart';
import 'endpoints/reference_data_api.dart';
import 'sync_result.dart';

/// The one place in the app that talks sync. Everything here is manual -
/// nothing runs on a timer or in the background. `syncAll()` only runs
/// when the person taps "Sync Now", and the UI only shows that control at
/// all once ConnectivityService says the device is truly online (see
/// SyncStatusBadge) - matching the hybrid app's core requirement: no
/// sync attempt is ever made, or even offered, while offline.
class SyncManager {
  SyncManager({
    required ConnectivityService connectivityService,
    required AppDatabase database,
    required this.deviceId,
    required GuestSyncApi guestApi,
    required BookingSyncApi bookingApi,
    required FoodOrderSyncApi foodOrderApi,
    required ServiceSyncApi serviceApi,
    required PaymentSyncApi paymentApi,
    required MaintenanceSyncApi maintenanceApi,
    required HousekeepingSyncApi housekeepingApi,
    required ReferenceDataApi referenceDataApi,
  })  : _connectivity = connectivityService,
        _db = database,
        _guestApi = guestApi,
        _bookingApi = bookingApi,
        _foodOrderApi = foodOrderApi,
        _serviceApi = serviceApi,
        _paymentApi = paymentApi,
        _maintenanceApi = maintenanceApi,
        _housekeepingApi = housekeepingApi,
        _referenceDataApi = referenceDataApi {
    _guestDao = GuestDao(_db);
    _bookingDao = BookingDao(_db);
    _foodOrderDao = FoodOrderDao(_db);
    _serviceRequestDao = ServiceRequestDao(_db);
    _paymentDao = PaymentDao(_db);
    _maintenanceDao = MaintenanceDao(_db);
    _housekeepingDao = HousekeepingDao(_db);
  }

  final ConnectivityService _connectivity;
  final AppDatabase _db;
  final String deviceId;

  final GuestSyncApi _guestApi;
  final BookingSyncApi _bookingApi;
  final FoodOrderSyncApi _foodOrderApi;
  final ServiceSyncApi _serviceApi;
  final PaymentSyncApi _paymentApi;
  final MaintenanceSyncApi _maintenanceApi;
  final HousekeepingSyncApi _housekeepingApi;
  final ReferenceDataApi _referenceDataApi;

  late final GuestDao _guestDao;
  late final BookingDao _bookingDao;
  late final FoodOrderDao _foodOrderDao;
  late final ServiceRequestDao _serviceRequestDao;
  late final PaymentDao _paymentDao;
  late final MaintenanceDao _maintenanceDao;
  late final HousekeepingDao _housekeepingDao;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<SyncResult> syncAll() async {
    if (_isSyncing) return SyncResult.error('A sync is already in progress');

    final reallyOnline = await _connectivity.isTrulyOnline();
    if (!reallyOnline) return SyncResult.offline();

    _isSyncing = true;
    try {
      final report = SyncReport();

      // Dependency order matters: guests before bookings before
      // food/service/payments, so foreign-uuid lookups on the server
      // always resolve.
      report.add(await _syncGuests());
      report.add(await _syncBookings());
      report.add(await _syncFoodOrders());
      report.add(await _syncServiceRequests());
      report.add(await _syncPayments());
      report.add(await _syncMaintenance());
      report.add(await _syncHousekeeping());

      await _pullReferenceData();
      await _pullActiveBookings();

      return SyncResult.done(report);
    } catch (e) {
      return SyncResult.error('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // -------------------------------------------------------------------
  // Push helpers - one per table. Each converts local rows into the
  // shape the backend controller expects, applies the response back to
  // the local row (SYNCED + server_id, or FAILED + error), and never
  // re-sends a row once it's marked SYNCED (see AppDatabase.getPending).
  // -------------------------------------------------------------------

  Future<TableSyncResult> _syncGuests() async {
    final pending = await _guestDao.pending();
    if (pending.isEmpty) return TableSyncResult.empty(GuestsTable.tableName);

    final records = pending
        .map((row) => {
              'uuid': row['uuid'],
              'name': row['name'],
              'mobile': row['mobile'],
              'email': row['email'],
              'id_proof_type': row['id_proof_type'],
              'id_proof_number': row['id_proof_number'],
              'address': row['address'],
            })
        .toList();

    return _pushAndApply(GuestsTable.tableName, records, (r) => _guestApi.push(r, deviceId));
  }

  Future<TableSyncResult> _syncBookings() async {
    final pending = await _bookingDao.pending();
    if (pending.isEmpty) return TableSyncResult.empty(BookingsTable.tableName);

    final records = pending
        .map((row) => {
              'uuid': row['uuid'],
              'guest_uuid': row['guest_uuid'],
              'room_id': row['room_id'],
              'check_in': row['check_in'],
              'check_out': row['check_out'],
              'adults': row['adults'],
              'children': row['children'],
              'room_rate': row['room_rate'],
              'nights': row['nights'],
              'room_total': row['room_total'],
              'discount': row['discount'],
              'tax_amount': row['tax_amount'],
              'grand_total': row['grand_total'],
              'advance_paid': row['advance_paid'],
              'status': row['status'],
              'booking_number': row['booking_number'],
            })
        .toList();

    return _pushAndApply(
      BookingsTable.tableName,
      records,
      (r) => _bookingApi.push(r, deviceId),
      // The server assigns the real BK-000123 booking number on first
      // sync (see syncBookings.controller.js) - write it back locally so
      // the UI stops showing "Pending booking number" after a
      // successful sync.
      extraFieldsBuilder: (result) {
        final bookingNumber = result['booking_number'] as String?;
        return bookingNumber == null ? null : {'booking_number': bookingNumber};
      },
    );
  }

  Future<TableSyncResult> _syncFoodOrders() async {
    final pending = await _foodOrderDao.pending();
    if (pending.isEmpty) return TableSyncResult.empty(FoodOrdersTable.tableName);

    final records = <Map<String, dynamic>>[];
    for (final row in pending) {
      final items = await _foodOrderDao.itemsFor(row['uuid'] as String);
      records.add({
        'uuid': row['uuid'],
        'booking_uuid': row['booking_uuid'],
        'room_id': row['room_id'],
        'guest_uuid': row['guest_uuid'],
        'status': row['status'],
        'items': items
            .map((i) => {
                  'product_name': i['product_name'],
                  'quantity': i['quantity'],
                  'price': i['price'],
                  'modifiers': i['modifiers'],
                  'notes': i['notes'],
                })
            .toList(),
      });
    }

    return _pushAndApply(FoodOrdersTable.tableName, records, (r) => _foodOrderApi.push(r, deviceId));
  }

  Future<TableSyncResult> _syncServiceRequests() async {
    final pending = await _serviceRequestDao.pending();
    if (pending.isEmpty) return TableSyncResult.empty(ServiceRequestsTable.tableName);

    final records = pending
        .map((row) => {
              'uuid': row['uuid'],
              'booking_uuid': row['booking_uuid'],
              'room_id': row['room_id'],
              'guest_uuid': row['guest_uuid'],
              'service_type_id': row['service_type_id'],
              'quantity': row['quantity'],
              'amount': row['amount'],
              'status': row['status'],
              'notes': row['notes'],
            })
        .toList();

    return _pushAndApply(ServiceRequestsTable.tableName, records, (r) => _serviceApi.push(r, deviceId));
  }

  Future<TableSyncResult> _syncPayments() async {
    final pending = await _paymentDao.pending();
    if (pending.isEmpty) return TableSyncResult.empty(PaymentsTable.tableName);

    final records = pending
        .map((row) => {
              'uuid': row['uuid'],
              'booking_uuid': row['booking_uuid'],
              'amount': row['amount'],
              'method': row['method'],
              'reference_no': row['reference_no'],
              'paid_at': row['paid_at'],
            })
        .toList();

    return _pushAndApply(PaymentsTable.tableName, records, (r) => _paymentApi.push(r, deviceId));
  }

  Future<TableSyncResult> _syncMaintenance() async {
    final pending = await _maintenanceDao.pending();
    if (pending.isEmpty) return TableSyncResult.empty(MaintenanceTable.tableName);

    final records = pending
        .map((row) => {
              'uuid': row['uuid'],
              'room_id': row['room_id'],
              'issue': row['issue'],
              'status': row['status'],
              'assigned_to': row['assigned_to'],
              'notes': row['notes'],
              'reported_at': row['reported_at'],
            })
        .toList();

    return _pushAndApply(MaintenanceTable.tableName, records, (r) => _maintenanceApi.push(r, deviceId));
  }

  Future<TableSyncResult> _syncHousekeeping() async {
    final pending = await _housekeepingDao.pending();
    if (pending.isEmpty) return TableSyncResult.empty(HousekeepingTable.tableName);

    final records = pending
        .map((row) => {
              'uuid': row['uuid'],
              'room_id': row['room_id'],
              'status': row['status'],
              'started_at': row['started_at'],
              'completed_at': row['completed_at'],
              'notes': row['notes'],
            })
        .toList();

    return _pushAndApply(HousekeepingTable.tableName, records, (r) => _housekeepingApi.push(r, deviceId));
  }

  /// Shared push + apply-results logic for every table above: send the
  /// batch, then for each result either mark the local row SYNCED (with
  /// the server's id) or FAILED (with the error message so it's visible
  /// and will be retried on the next sync tap).
  Future<TableSyncResult> _pushAndApply(
    String table,
    List<Map<String, dynamic>> records,
    Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>) send, {
    Map<String, dynamic>? Function(Map<String, dynamic> result)? extraFieldsBuilder,
  }) async {
    try {
      final results = await send(records);
      var succeeded = 0;
      var failed = 0;
      final errors = <String>[];

      for (final result in results) {
        final uuid = result['uuid'] as String;
        final status = result['status'] as String;

        if (status == 'created' || status == 'updated') {
          final serverId = result['id'] as int?;
          await _db.markSynced(table, uuid, serverId: serverId, extraFields: extraFieldsBuilder?.call(result));
          succeeded++;
        } else {
          final error = (result['error'] as String?) ?? 'Sync failed';
          await _db.markFailed(table, uuid, error);
          failed++;
          errors.add('$uuid: $error');
        }
      }

      return TableSyncResult(
        table: table,
        attempted: records.length,
        succeeded: succeeded,
        failed: failed,
        errors: errors,
      );
    } catch (e) {
      // Network-level failure (timeout, server error) - leave every row
      // PENDING so the whole batch is retried next time, rather than
      // guessing at partial success.
      return TableSyncResult(
        table: table,
        attempted: records.length,
        succeeded: 0,
        failed: records.length,
        errors: ['Batch request failed: $e'],
      );
    }
  }

  // -------------------------------------------------------------------
  // Pull helpers - refresh the read-only reference caches and other
  // devices' active bookings.
  // -------------------------------------------------------------------

  Future<void> _pullReferenceData() async {
    const cursorKey = 'reference_data';
    final since = await _db.getSyncCursor(cursorKey) ?? '1970-01-01T00:00:00.000Z';

    final data = await _referenceDataApi.pull(since);

    await _db.upsertReferenceRows(RoomsTable.tableName, List<Map<String, dynamic>>.from(data['rooms'] as List),
        allowedColumns: RoomsTable.columns);
    await _db.upsertReferenceRows(
        RoomTypesTable.tableName, List<Map<String, dynamic>>.from(data['roomTypes'] as List),
        allowedColumns: RoomTypesTable.columns);
    await _db.upsertReferenceRows(
        AmenitiesTable.tableName, List<Map<String, dynamic>>.from(data['amenities'] as List),
        allowedColumns: AmenitiesTable.columns);
    await _db.upsertReferenceRows(TaxesTable.tableName, List<Map<String, dynamic>>.from(data['taxes'] as List),
        allowedColumns: TaxesTable.columns);
    await _db.upsertReferenceRows(
        ServiceTypesTable.tableName, List<Map<String, dynamic>>.from(data['serviceTypes'] as List),
        allowedColumns: ServiceTypesTable.columns);
    await _db.upsertReferenceRows(
        PaymentMethodsTable.tableName, List<Map<String, dynamic>>.from(data['paymentMethods'] as List),
        allowedColumns: PaymentMethodsTable.columns);

    final hotelSettings = data['hotelSettings'];
    if (hotelSettings != null) {
      await _db.upsertReferenceRows(
        HotelSettingsTable.tableName,
        [Map<String, dynamic>.from(hotelSettings as Map)],
        allowedColumns: HotelSettingsTable.columns,
      );
    }

    final serverTime = data['server_time'] as String?;
    if (serverTime != null) {
      await _db.setSyncCursor(cursorKey, serverTime);
    }
  }

  Future<void> _pullActiveBookings() async {
    const cursorKey = 'active_bookings';
    final since = await _db.getSyncCursor(cursorKey) ?? '1970-01-01T00:00:00.000Z';

    final bookings = await _bookingApi.pullActiveBookings(since);
    final db = await _db.database;
    final batch = db.batch();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    for (final b in bookings) {
      // These arrive with a server-authoritative uuid and are only ever
      // used locally for availability overlap checks, so they're inserted
      // as already-SYNCED and never picked up by the push side of sync.
      // guest_uuid is irrelevant for a read-only row like this (the schema
      // just requires a non-null value), so an empty sentinel is used
      // rather than something that could be confused for a real guest.
      batch.insert(
        BookingsTable.tableName,
        {
          'uuid': b['uuid'],
          'guest_uuid': '',
          'room_id': b['room_id'],
          'check_in': b['check_in'],
          'check_out': b['check_out'],
          'status': b['status'],
          'sync_status': 'SYNCED',
          'created_at': nowIso,
          'updated_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    // ConflictAlgorithm.ignore above ensures a row this device already
    // owns (and may still have PENDING) is never clobbered by the
    // read-only cross-device cache - only genuinely new rows are inserted.
    await batch.commit(noResult: true, continueOnError: true);

    await _db.setSyncCursor(cursorKey, DateTime.now().toUtc().toIso8601String());
  }
}
