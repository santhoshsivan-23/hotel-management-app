import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connectivity/connectivity_service.dart';
import '../connectivity/connectivity_state.dart';
import '../db/app_database.dart';
import '../sync/sync_manager.dart';
import '../sync/sync_result.dart';
import '../sync/sync_status.dart';
import '../theme/colors.dart';

/// The one UI control the whole hybrid-sync design revolves around:
///   - Offline -> nothing tappable is shown at all (badge collapses to a
///     small grey "Offline" pill) - there's nothing to tap that would
///     just fail.
///   - Online, nothing pending -> a quiet "All synced" pill.
///   - Online, N pending -> "N pending - tap to sync", tappable.
///   - Mid-sync -> a spinner, not tappable (prevents double-taps).
class SyncStatusBadge extends StatefulWidget {
  const SyncStatusBadge({super.key});

  @override
  State<SyncStatusBadge> createState() => _SyncStatusBadgeState();
}

class _SyncStatusBadgeState extends State<SyncStatusBadge> {
  int _pendingCount = 0;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _refreshPendingCount();
  }

  Future<void> _refreshPendingCount() async {
    final count = await AppDatabase.instance.countAllPending();
    if (mounted) setState(() => _pendingCount = count);
  }

  Future<void> _handleTap() async {
    if (_syncing || _pendingCount == 0) return;

    setState(() => _syncing = true);
    final syncManager = context.read<SyncManager>();
    final result = await syncManager.syncAll();
    await _refreshPendingCount();

    if (!mounted) return;
    setState(() => _syncing = false);
    _showResultSnackBar(result);
  }

  void _showResultSnackBar(SyncResult result) {
    final messenger = ScaffoldMessenger.of(context);
    if (result.state == SyncRunState.offline) {
      messenger.showSnackBar(SnackBar(content: Text(result.message ?? 'Offline')));
      return;
    }
    if (result.report != null) {
      final report = result.report!;
      final text = report.totalFailed == 0
          ? '${report.totalSucceeded} synced'
          : '${report.totalSucceeded} synced, ${report.totalFailed} failed (will retry next sync)';
      messenger.showSnackBar(SnackBar(content: Text(text)));
    } else if (result.message != null) {
      messenger.showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();

    return StreamBuilder<ConnectivityState>(
      stream: connectivity.stream,
      initialData: connectivity.lastState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? ConnectivityState.offline;

        if (state == ConnectivityState.offline) {
          return _buildPill(
            icon: Icons.cloud_off,
            label: 'Offline',
            color: AppColors.syncOffline,
          );
        }

        if (_syncing) {
          return _buildPill(
            icon: null,
            label: 'Syncing...',
            color: AppColors.syncPending,
            leading: const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          );
        }

        if (_pendingCount == 0) {
          return _buildPill(icon: Icons.cloud_done, label: 'All synced', color: AppColors.syncSynced);
        }

        return InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(20),
          child: _buildPill(
            icon: Icons.cloud_upload,
            label: '$_pendingCount pending - Sync now',
            color: AppColors.syncPending,
          ),
        );
      },
    );
  }

  Widget _buildPill({
    required String label,
    required Color color,
    IconData? icon,
    Widget? leading,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading ?? Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
