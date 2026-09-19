import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class TodaysActivityCard extends StatelessWidget {
  const TodaysActivityCard({
    super.key,
    required this.checkins,
    required this.checkouts,
    required this.reservations,
    required this.pendingPayments,
  });

  final int checkins;
  final int checkouts;
  final int reservations;
  final int pendingPayments;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ("Today's Check-ins", checkins, Icons.login),
      ("Today's Check-outs", checkouts, Icons.logout),
      ("Today's Reservations", reservations, Icons.event_available),
      ('Pending Payments', pendingPayments, Icons.payment),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            ...rows.map((r) {
              final (label, value, icon) = r;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(label)),
                    Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
