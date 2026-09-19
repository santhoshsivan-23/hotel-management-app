import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../routes/app_router.dart';
import '../../providers/room_provider.dart';
import 'add_edit_room_screen.dart';
import 'room_details_screen.dart';

class RoomListScreen extends StatelessWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RoomProvider(
        database: context.read<AppDatabase>(),
        apiClient: context.read<ApiClient>(),
      )..load(),
      child: const _RoomListView(),
    );
  }
}

class _RoomListView extends StatelessWidget {
  const _RoomListView();

  static const _statusFilters = [
    null, 'AVAILABLE', 'RESERVED', 'OCCUPIED', 'DIRTY', 'CLEANING', 'MAINTENANCE',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoomProvider>();

    return AppScaffold(
      title: 'Rooms',
      currentRoute: AppRoutes.rooms,
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = _statusFilters[index];
                final selected = provider.statusFilter == status;
                return ChoiceChip(
                  label: Text(status ?? 'All'),
                  selected: selected,
                  onSelected: (_) => context.read<RoomProvider>().setStatusFilter(status),
                );
              },
            ),
          ),
          Expanded(
            child: provider.loading
                ? const LoadingIndicator()
                : provider.rooms.isEmpty
                    ? const EmptyState(message: 'No rooms found', icon: Icons.meeting_room_outlined)
                    : RefreshIndicator(
                        onRefresh: provider.load,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 180,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: provider.rooms.length,
                          itemBuilder: (context, index) {
                            final room = provider.rooms[index];
                            return Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => RoomDetailsScreen(room: room)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(room.roomNumber,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      Text(room.roomTypeName ?? '', style: const TextStyle(fontSize: 12)),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.statusColor(room.status),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          room.status,
                                          style: const TextStyle(color: Colors.white, fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditRoomScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
