import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../data/models/guest_model.dart';
import '../../providers/guest_provider.dart';
import 'add_edit_guest_screen.dart';

class GuestDetailsScreen extends StatelessWidget {
  const GuestDetailsScreen({super.key, required this.guest});
  final GuestModel guest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(guest.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddEditGuestScreen(existing: guest)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Delete Guest',
                message: 'Delete ${guest.name}? This cannot be undone.',
                isDestructive: true,
              );
              if (confirmed && context.mounted) {
                await context.read<GuestProvider>().deleteGuest(guest.uuid);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (guest.isPending)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.syncPending.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: const Text('Not yet synced to the server', style: TextStyle(fontSize: 12)),
            ),
          _infoTile('Mobile', guest.mobile),
          _infoTile('Email', guest.email ?? '-'),
          _infoTile('ID Proof', '${guest.idProofType ?? '-'} ${guest.idProofNumber ?? ''}'),
          _infoTile('Address', guest.address ?? '-'),
          const Divider(height: 32),
          const Text('Booking History', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Booking history for this guest is available from the Reservations tab, filtered by guest.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
