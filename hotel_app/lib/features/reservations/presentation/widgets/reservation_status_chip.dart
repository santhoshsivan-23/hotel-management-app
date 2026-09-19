import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class ReservationStatusChip extends StatelessWidget {
  const ReservationStatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.statusColor(status), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
