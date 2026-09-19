import 'sync_status.dart';

/// Outcome of pushing one table's pending rows.
class TableSyncResult {
  TableSyncResult({
    required this.table,
    required this.attempted,
    required this.succeeded,
    required this.failed,
    this.errors = const [],
  });

  final String table;
  final int attempted;
  final int succeeded;
  final int failed;
  final List<String> errors;

  factory TableSyncResult.empty(String table) =>
      TableSyncResult(table: table, attempted: 0, succeeded: 0, failed: 0);
}

/// Outcome of a full "Sync Now" tap, across every table.
class SyncReport {
  final List<TableSyncResult> tableResults = [];

  void add(TableSyncResult result) => tableResults.add(result);

  int get totalSucceeded => tableResults.fold(0, (sum, r) => sum + r.succeeded);
  int get totalFailed => tableResults.fold(0, (sum, r) => sum + r.failed);
  int get totalAttempted => tableResults.fold(0, (sum, r) => sum + r.attempted);

  List<String> get allErrors => tableResults.expand((r) => r.errors).toList();
}

class SyncResult {
  SyncResult._(this.state, {this.report, this.message});

  final SyncRunState state;
  final SyncReport? report;
  final String? message;

  factory SyncResult.offline() =>
      SyncResult._(SyncRunState.offline, message: 'No internet connection - connect and try again');

  factory SyncResult.done(SyncReport report) => SyncResult._(SyncRunState.done, report: report);

  factory SyncResult.error(String message) => SyncResult._(SyncRunState.done, message: message);
}
