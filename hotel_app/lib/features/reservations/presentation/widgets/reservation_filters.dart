import 'package:flutter/material.dart';

class ReservationFilters extends StatelessWidget {
  const ReservationFilters({super.key, required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  static const _statuses = [null, 'PENDING', 'CONFIRMED', 'CHECKED_IN', 'CHECKED_OUT', 'CANCELLED', 'NO_SHOW'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = _statuses[index];
          return ChoiceChip(
            label: Text(status ?? 'All'),
            selected: selected == status,
            onSelected: (_) => onChanged(status),
          );
        },
      ),
    );
  }
}
