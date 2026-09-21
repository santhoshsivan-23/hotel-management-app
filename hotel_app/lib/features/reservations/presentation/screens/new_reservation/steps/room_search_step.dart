import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/db/app_database.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/theme/colors.dart';
import '../../../../../../core/utils/currency_formatter.dart';
import '../../../../../../core/utils/date_utils.dart';
import '../../../../../../core/widgets/empty_state.dart';
import '../../../../../../core/widgets/loading_indicator.dart';
import '../../../../../rooms/data/models/room_model.dart';
import '../../../../../rooms/data/repositories/room_repository.dart';
import '../reservation_wizard_state.dart';

/// "System checks: room exists + capacity + status + existing reservations
/// + date overlap. Then show available rooms" - clearly separates Available
/// and Already Booked/Unavailable rooms with conflict details.
class RoomSearchStep extends StatefulWidget {
  const RoomSearchStep({super.key, required this.state, required this.onChanged});
  final ReservationWizardState state;
  final VoidCallback onChanged;

  @override
  State<RoomSearchStep> createState() => _RoomSearchStepState();
}

class _RoomSearchStepState extends State<RoomSearchStep> {
  late final RoomRepository _repository;
  List<RoomModel> _availableRooms = [];
  List<RoomModel> _unavailableRooms = [];
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
          _availableRooms = [];
          _unavailableRooms = [];
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
      final result = await _repository.getAvailabilityStatus(
        checkIn: widget.state.checkIn!,
        checkOut: widget.state.checkOut!,
        capacity: widget.state.adults + widget.state.children,
      );
      if (!mounted) return;
      setState(() {
        _availableRooms = result.available;
        _unavailableRooms = result.unavailable;
        // If current selectedRoom is in unavailableRooms, clear selection
        if (widget.state.selectedRoom != null &&
            _unavailableRooms.any((r) => r.id == widget.state.selectedRoom!.id)) {
          widget.state.selectedRoom = null;
          widget.onChanged();
        }
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

  String _formatConflictDates(Map<String, dynamic> conflict) {
    final checkIn = DateTime.tryParse(conflict['check_in']?.toString() ?? '');
    final checkOut = DateTime.tryParse(conflict['check_out']?.toString() ?? '');
    final bNum = conflict['booking_number']?.toString();
    final inStr = checkIn != null ? AppDateUtils.formatDisplayDate(checkIn) : conflict['check_in']?.toString() ?? '';
    final outStr = checkOut != null ? AppDateUtils.formatDisplayDate(checkOut) : conflict['check_out']?.toString() ?? '';
    final bNumStr = bNum != null && bNum.isNotEmpty ? ' ($bNum)' : '';
    return 'Booked: $inStr – $outStr$bNumStr';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingIndicator();

    if (_error != null) {
      return Center(
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
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 6),
                    Text('Available (${_availableRooms.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text('Already Booked (${_unavailableRooms.length})'),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Available Rooms Tab
                _availableRooms.isEmpty
                    ? const EmptyState(
                        message: 'No rooms available for these dates.\nCheck the "Already Booked" tab or select different dates.',
                        icon: Icons.search_off,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _availableRooms.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final room = _availableRooms[index];
                          final selected = widget.state.selectedRoom?.id == room.id;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: selected ? AppColors.primary : AppColors.divider,
                              child: Text(room.roomNumber, style: const TextStyle(fontSize: 11, color: Colors.white)),
                            ),
                            title: Text('${room.roomTypeName ?? 'Room'} - ${room.roomNumber}'),
                            subtitle: Text('Capacity: ${room.capacity} guests • Floor: ${room.floor ?? '-'}'),
                            trailing: Text(
                              '${CurrencyFormatter.format(room.price)}/night',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            selected: selected,
                            onTap: () {
                              setState(() => widget.state.selectedRoom = room);
                              widget.onChanged();
                            },
                          );
                        },
                      ),

                // Already Booked / Unavailable Rooms Tab
                _unavailableRooms.isEmpty
                    ? const EmptyState(
                        message: 'No unavailable rooms for these dates.',
                        icon: Icons.check_circle_outline,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _unavailableRooms.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final room = _unavailableRooms[index];
                          final isMaintenance = room.unavailableReason == 'MAINTENANCE' ||
                              room.unavailableReason == 'OUT_OF_SERVICE';

                          return ListTile(
                            enabled: false,
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade300,
                              child: Icon(
                                isMaintenance ? Icons.build_circle_outlined : Icons.event_busy,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            title: Text(
                              '${room.roomTypeName ?? 'Room'} - ${room.roomNumber}',
                              style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                if (isMaintenance)
                                  Text(
                                    'Unavailable (${room.unavailableReason})',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                                  )
                                else if (room.conflicts.isNotEmpty)
                                  ...room.conflicts.map((c) => Text(
                                        _formatConflictDates(c),
                                        style: const TextStyle(color: Colors.red, fontSize: 12),
                                      ))
                                else
                                  Text(
                                    'Unavailable (${room.status})',
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                Text(
                                  'Capacity: ${room.capacity} • Price: ${CurrencyFormatter.format(room.price)}/night',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                ),
                              ],
                            ),
                            trailing: const Chip(
                              label: Text('Not Available', style: TextStyle(fontSize: 10, color: Colors.white)),
                              backgroundColor: Colors.grey,
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
