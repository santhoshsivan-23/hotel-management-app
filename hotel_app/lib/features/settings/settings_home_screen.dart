import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/permission_service.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../routes/app_router.dart';

class _SettingsTile {
  const _SettingsTile(this.title, this.icon, this.route, {this.adminOnly = false});
  final String title;
  final IconData icon;
  final String route;
  final bool adminOnly;
}

/// Settings landing screen: Room Types, Amenities, Service Types,
/// Tax & Charges, Payment Methods, Users & Roles, Hotel/Business Settings.
class SettingsHomeScreen extends StatelessWidget {
  const SettingsHomeScreen({super.key});

  static const _tiles = [
    _SettingsTile('Room Types', Icons.category_outlined, AppRoutes.settingsRoomTypes),
    _SettingsTile('Amenities', Icons.checkroom_outlined, AppRoutes.settingsAmenities),
    _SettingsTile('Service Types', Icons.room_service_outlined, AppRoutes.settingsServiceTypes),
    _SettingsTile('Tax & Charges', Icons.receipt_long_outlined, AppRoutes.settingsTaxCharges),
    _SettingsTile('Payment Methods', Icons.credit_card_outlined, AppRoutes.settingsPaymentMethods),
    _SettingsTile('Users & Roles', Icons.admin_panel_settings_outlined, AppRoutes.settingsUsersRoles,
        adminOnly: true),
    _SettingsTile('Hotel / Business Settings', Icons.store_outlined, AppRoutes.settingsHotelBusinessSettings,
        adminOnly: true),
  ];

  @override
  Widget build(BuildContext context) {
    final permissions = context.watch<PermissionService>();
    final tiles = _tiles.where((t) => !t.adminOnly || permissions.canManageSettings).toList();

    return AppScaffold(
      title: 'Settings',
      currentRoute: AppRoutes.settingsHome,
      body: ListView.separated(
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final tile = tiles[index];
          return ListTile(
            leading: Icon(tile.icon),
            title: Text(tile.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(tile.route),
          );
        },
      ),
    );
  }
}
