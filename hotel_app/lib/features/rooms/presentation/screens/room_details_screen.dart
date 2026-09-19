import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/room_model.dart';
import '../../providers/room_provider.dart';

class RoomDetailsScreen extends StatelessWidget {
  const RoomDetailsScreen({super.key, required this.room});
  final RoomModel room;

  static const _statuses = [
    'AVAILABLE', 'RESERVED', 'OCCUPIED', 'DIRTY', 'CLEANING', 'MAINTENANCE', 'OUT_OF_SERVICE',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room ${room.roomNumber}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Chip(
                label: Text(room.status, style: const TextStyle(color: Colors.white)),
                backgroundColor: AppColors.statusColor(room.status),
              ),
              const SizedBox(width: 8),
              Text(room.roomTypeName ?? 'Room type #${room.roomTypeId}'),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Floor', room.floor ?? '-'),
          _infoRow('Capacity', '${room.capacity} guests'),
          _infoRow('Price / night', CurrencyFormatter.format(room.price)),
          const Divider(height: 32),
          const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statuses.map((status) {
              final isCurrent = status == room.status;
              return ChoiceChip(
                label: Text(status),
                selected: isCurrent,
                onSelected: isCurrent
                    ? null
                    : (_) async {
                        final error = await context.read<RoomProvider>().updateStatus(room.id, status);
                        if (context.mounted) {
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                          } else {
                            Navigator.of(context).pop();
                          }
                        }
                      },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
