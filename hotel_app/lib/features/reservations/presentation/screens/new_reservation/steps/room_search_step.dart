import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/db/app_database.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/theme/colors.dart';
import '../../../../../../core/utils/currency_formatter.dart';
import '../../../../../../core/widgets/empty_state.dart';
import '../../../../../../core/widgets/loading_indicator.dart';
import '../../../../../rooms/data/models/room_model.dart';
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
  List<RoomModel> _rooms = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = RoomRepository(database: context.read<AppDatabase>(), apiClient: context.read<ApiClient>());
    _search();
  }

  @override
  void didUpdateWidget(covariant RoomSearchStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.checkIn != oldWidget.state.checkIn ||
        widget.state.checkOut != oldWidget.state.checkOut ||
        widget.state.adults != oldWidget.state.adults ||
        widget.state.children != oldWidget.state.children) {
      _search();
    }
  }

  Future<void> _search() async {
    if (widget.state.checkIn == null || widget.state.checkOut == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _rooms = [];
          _error = null;
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Error checking room availability: $e';
      });
    }
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
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _search,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
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
