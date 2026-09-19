import 'package:flutter/material.dart';
import '../../../../routes/app_router.dart';
import '../../../guests/presentation/screens/add_edit_guest_screen.dart';
import '../../../reservations/presentation/screens/new_reservation/new_reservation_screen.dart';

class _QuickAction {
  const _QuickAction(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// "+ New Reservation, Check-in, Check-out, Add Guest, View Rooms" - the
/// dashboard's fast paths into the most common front-desk tasks.
class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  static const _actions = [
    _QuickAction('New Reservation', Icons.add_circle_outline),
    _QuickAction('Check-in', Icons.login),
    _QuickAction('Check-out', Icons.logout),
    _QuickAction('Add Guest', Icons.person_add_outlined),
    _QuickAction('View Rooms', Icons.meeting_room_outlined),
  ];

  void _handle(BuildContext context, String label) {
    switch (label) {
      case 'New Reservation':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewReservationScreen()));
        break;
      case 'Check-in':
      case 'Check-out':
        Navigator.of(context).pushNamed(AppRoutes.checkinCheckout);
        break;
      case 'Add Guest':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditGuestScreen()));
        break;
      case 'View Rooms':
        Navigator.of(context).pushNamed(AppRoutes.rooms);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final action = _actions[index];
          return InkWell(
            onTap: () => _handle(context, action.label),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 96,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 6),
                  Text(action.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
