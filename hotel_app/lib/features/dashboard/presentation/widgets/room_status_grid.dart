import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

/// "Simple room-status overview: Available, Reserved, Occupied, Cleaning,
/// Maintenance" - shown as colored count chips rather than a full grid of
/// every room (that's what the Rooms screen is for).
class RoomStatusGrid extends StatelessWidget {
  const RoomStatusGrid({
    super.key,
    required this.available,
    required this.reserved,
    required this.occupied,
    required this.maintenance,
  });

  final int available;
  final int reserved;
  final int occupied;
  final int maintenance;

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Available', available, AppColors.roomAvailable),
      ('Reserved', reserved, AppColors.roomReserved),
      ('Occupied', occupied, AppColors.roomOccupied),
      ('Maintenance', maintenance, AppColors.roomMaintenance),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: entries.map((e) {
        final (label, count, color) = e;
        return Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
