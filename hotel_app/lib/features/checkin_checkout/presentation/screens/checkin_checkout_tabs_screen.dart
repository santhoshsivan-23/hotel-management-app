import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../routes/app_router.dart';
import '../../../reservations/data/models/booking_model.dart';
import '../../providers/stay_provider.dart';
import 'active_stay_screen.dart';
import 'checkin_screen.dart';

class CheckinCheckoutTabsScreen extends StatelessWidget {
  const CheckinCheckoutTabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StayProvider(context.read<AppDatabase>())..load(),
      child: DefaultTabController(
        length: 3,
        child: Builder(
          builder: (context) => AppScaffold(
            title: 'Check-in / Check-out',
            currentRoute: AppRoutes.checkinCheckout,
            body: Column(
              children: [
                const TabBar(
                  labelColor: AppColors.primary,
                  tabs: [
                    Tab(text: "Today's Arrivals"),
                    Tab(text: 'Active Stays'),
                    Tab(text: "Today's Departures"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ArrivalsTab(),
                      _ActiveStaysTab(),
                      _DeparturesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrivalsTab extends StatelessWidget {
  const _ArrivalsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StayProvider>();
    if (provider.loading) return const LoadingIndicator();
    if (provider.arrivals.isEmpty) {
      return const EmptyState(message: 'No arrivals scheduled for today', icon: Icons.flight_land);
    }
    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView.separated(
        itemCount: provider.arrivals.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _bookingTile(context, provider.arrivals[index], isArrival: true),
      ),
    );
  }
}

class _ActiveStaysTab extends StatelessWidget {
  const _ActiveStaysTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StayProvider>();
    if (provider.loading) return const LoadingIndicator();
    if (provider.activeStays.isEmpty) {
      return const EmptyState(message: 'No active stays right now', icon: Icons.hotel_outlined);
    }
    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView.separated(
        itemCount: provider.activeStays.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _bookingTile(context, provider.activeStays[index]),
      ),
    );
  }
}

class _DeparturesTab extends StatelessWidget {
  const _DeparturesTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StayProvider>();
    if (provider.loading) return const LoadingIndicator();
    if (provider.departures.isEmpty) {
      return const EmptyState(message: 'No departures scheduled for today', icon: Icons.flight_takeoff);
    }
    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView.separated(
        itemCount: provider.departures.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _bookingTile(context, provider.departures[index]),
      ),
    );
  }
}

Widget _bookingTile(BuildContext context, BookingModel booking, {bool isArrival = false}) {
  return ListTile(
    title: Text(booking.guestName ?? 'Guest'),
    subtitle: Text(
      'Room ${booking.roomNumber ?? booking.roomId} • '
      '${AppDateUtils.formatDisplayDate(booking.checkIn)} - ${AppDateUtils.formatDisplayDate(booking.checkOut)}',
    ),
    trailing: isArrival ? const Icon(Icons.chevron_right) : const Icon(Icons.chevron_right),
    onTap: () async {
      if (isArrival) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CheckinScreen(booking: booking)),
        );
        if (result == true && context.mounted) context.read<StayProvider>().load();
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ActiveStayScreen(bookingUuid: booking.uuid)),
        );
        if (context.mounted) context.read<StayProvider>().load();
      }
    },
  );
}
