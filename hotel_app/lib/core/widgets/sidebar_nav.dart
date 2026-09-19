import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../theme/colors.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

/// The app's sidebar, matching the master spec's Final Recommended
/// Sidebar: Dashboard, Reservations, Rooms, Guests, Check-in/Check-out,
/// In-Room Orders, Room Services, Payments & Billing, Reports, Settings.
/// Rendered as a Drawer so it works the same on phones and tablets.
class SidebarNav extends StatelessWidget {
  const SidebarNav({super.key, required this.currentRoute});
  final String currentRoute;

  static const _items = [
    _NavItem('Dashboard', Icons.dashboard_outlined, AppRoutes.dashboard),
    _NavItem('Reservations', Icons.event_note_outlined, AppRoutes.reservations),
    _NavItem('Rooms', Icons.meeting_room_outlined, AppRoutes.rooms),
    _NavItem('Guests', Icons.people_outline, AppRoutes.guests),
    _NavItem('Check-in / Check-out', Icons.key_outlined, AppRoutes.checkinCheckout),
    _NavItem('In-Room Orders', Icons.restaurant_outlined, AppRoutes.foodOrders),
    _NavItem('Room Services', Icons.room_service_outlined, AppRoutes.roomServices),
    _NavItem('Payments & Billing', Icons.payments_outlined, AppRoutes.paymentsBilling),
    _NavItem('Reports', Icons.bar_chart_outlined, AppRoutes.reports),
    _NavItem('Settings', Icons.settings_outlined, AppRoutes.settingsHome),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.hotel, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    auth.user?['name'] as String? ?? 'Hotel Manager',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    auth.user?['role'] as String? ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _items.map((item) {
                  final selected = item.route == currentRoute;
                  return ListTile(
                    leading: Icon(item.icon, color: selected ? AppColors.primary : AppColors.textSecondary),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: selected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                    selected: selected,
                    selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                    onTap: () {
                      Navigator.of(context).pop(); // close the drawer
                      if (!selected) {
                        Navigator.of(context).pushReplacementNamed(item.route);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Log out', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.of(context).pop();
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
