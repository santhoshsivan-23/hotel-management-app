/// Per-record lifecycle stored in each syncable table's `sync_status`
/// column, and the overall app-level state shown by SyncStatusBadge.
enum SyncRecordStatus { pending, syncing, synced, failed }

enum SyncRunState { idle, offline, syncing, done }
