import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../routes/app_router.dart';
import '../../providers/reservation_provider.dart';
import '../widgets/reservation_filters.dart';
import '../widgets/reservation_status_chip.dart';
import 'new_reservation/new_reservation_screen.dart';
import 'reservation_details_screen.dart';

class ReservationListScreen extends StatelessWidget {
  const ReservationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReservationProvider(context.read<AppDatabase>())..load(),
      child: const _ReservationListView(),
    );
  }
}

class _ReservationListView extends StatelessWidget {
  const _ReservationListView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();

    return AppScaffold(
      title: 'Reservations',
      currentRoute: AppRoutes.reservations,
      body: Column(
        children: [
          ReservationFilters(
            selected: provider.statusFilter,
            onChanged: (status) => context.read<ReservationProvider>().setStatusFilter(status),
          ),
          Expanded(
            child: provider.loading
                ? const LoadingIndicator()
                : provider.bookings.isEmpty
                    ? const EmptyState(message: 'No reservations found', icon: Icons.event_busy_outlined)
                    : RefreshIndicator(
                        onRefresh: provider.load,
                        child: ListView.separated(
                          itemCount: provider.bookings.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final booking = provider.bookings[index];
                            return ListTile(
                              title: Text(booking.guestName ?? 'Guest'),
                              subtitle: Text(
                                'Room ${booking.roomNumber ?? booking.roomId} • '
                                '${AppDateUtils.formatDisplayDate(booking.checkIn)} - '
                                '${AppDateUtils.formatDisplayDate(booking.checkOut)}',
                              ),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ReservationStatusChip(status: booking.status),
                                  const SizedBox(height: 4),
                                  Text(CurrencyFormatter.format(booking.grandTotal),
                                      style: const TextStyle(fontSize: 12)),
                                  if (booking.isPending)
                                    const Icon(Icons.cloud_upload_outlined, size: 14, color: AppColors.syncPending),
                                ],
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ReservationDetailsScreen(bookingUuid: booking.uuid)),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Reservation'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewReservationScreen()),
          );
          if (context.mounted) context.read<ReservationProvider>().load();
        },
      ),
    );
  }
}
