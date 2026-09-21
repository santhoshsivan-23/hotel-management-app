import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../routes/app_router.dart';
import '../../providers/guest_provider.dart';
import 'add_edit_guest_screen.dart';
import 'guest_details_screen.dart';

class GuestListScreen extends StatelessWidget {
  const GuestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GuestProvider(context.read<AppDatabase>())..load(),
      child: const _GuestListView(),
    );
  }
}

class _GuestListView extends StatefulWidget {
  const _GuestListView();

  @override
  State<_GuestListView> createState() => _GuestListViewState();
}

class _GuestListViewState extends State<_GuestListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuestProvider>();

    return AppScaffold(
      title: 'Guests',
      currentRoute: AppRoutes.guests,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name, mobile or email',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => context.read<GuestProvider>().search(value),
            ),
          ),
          Expanded(
            child: provider.loading
                ? const LoadingIndicator()
                : provider.guests.isEmpty
                    ? const EmptyState(message: 'No guests yet', icon: Icons.people_outline)
                    : RefreshIndicator(
                        onRefresh: provider.load,
                        child: ListView.separated(
                          itemCount: provider.guests.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final guest = provider.guests[index];
                            return ListTile(
                              leading: CircleAvatar(child: Text(guest.name.isNotEmpty ? guest.name[0] : '?')),
                              title: Text(guest.name),
                              subtitle: Text(guest.mobile),
                              trailing: guest.isPending
                                  ? const Icon(Icons.cloud_upload_outlined, size: 18, color: AppColors.syncPending)
                                  : null,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => GuestDetailsScreen(guest: guest)),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddEditGuestScreen()),
          );
          if (created == true && context.mounted) {
            context.read<GuestProvider>().load();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
