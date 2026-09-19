import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/db/app_database.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/theme/colors.dart';
import '../../../../../../core/utils/currency_formatter.dart';
import '../../../../../../core/widgets/empty_state.dart';
import '../../../../../../core/widgets/loading_indicator.dart';
import '../../../../../rooms/data/repositories/room_repository.dart';
import '../reservation_wizard_state.dart';

/// "System checks: room exists + capacity + status + existing reservations
/// + date overlap. Then show available rooms" - works entirely from the
/// local cache, so this step is instant and fully usable offline.
class RoomSearchStep extends StatefulWidget {
  const RoomSearchStep({super.key, required this.state, required this.onChanged});
  final ReservationWizardState state;
  final VoidCallback onChanged;

  @override
  State<RoomSearchStep> createState() => _RoomSearchStepState();
}

class _RoomSearchStepState extends State<RoomSearchStep> {
  late final RoomRepository _repository;
  List<dynamic> _rooms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = RoomRepository(database: context.read<AppDatabase>(), apiClient: context.read<ApiClient>());
    _search();
  }

  Future<void> _search() async {
    if (widget.state.checkIn == null || widget.state.checkOut == null) return;
    setState(() => _loading = true);
    final rooms = await _repository.findAvailable(
      checkIn: widget.state.checkIn!,
      checkOut: widget.state.checkOut!,
      capacity: widget.state.adults + widget.state.children,
    );
    if (!mounted) return;
    setState(() {
      _rooms = rooms;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text('Available Rooms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _search),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingIndicator()
              : _rooms.isEmpty
                  ? const EmptyState(message: 'No rooms available for these dates', icon: Icons.search_off)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _rooms.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final room = _rooms[index];
                        final selected = widget.state.selectedRoom?.id == room.id;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: selected ? AppColors.primary : AppColors.divider,
                            child: Text(room.roomNumber, style: const TextStyle(fontSize: 11, color: Colors.white)),
                          ),
                          title: Text('${room.roomTypeName ?? 'Room'} - ${room.roomNumber}'),
                          subtitle: Text('Capacity: ${room.capacity}'),
                          trailing: Text(
                            '${CurrencyFormatter.format(room.price)}/night',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          selected: selected,
                          onTap: () {
                            setState(() => widget.state.selectedRoom = room);
                            widget.onChanged();
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
