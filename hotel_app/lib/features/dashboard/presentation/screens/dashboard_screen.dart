import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../routes/app_router.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/room_status_grid.dart';
import '../widgets/todays_activity_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DashboardProvider(context.read<AppDatabase>())..load(),
      child: Consumer<DashboardProvider>(
        builder: (context, provider, _) => AppScaffold(
          title: 'Dashboard',
          currentRoute: AppRoutes.dashboard,
          body: provider.loading
              ? const LoadingIndicator()
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const QuickActionsBar(),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          StatCard(label: 'Total Rooms', value: '${provider.totalRooms}', icon: Icons.hotel),
                          StatCard(label: 'Available', value: '${provider.available}', icon: Icons.check_circle_outline),
                          StatCard(label: 'Reserved', value: '${provider.reserved}', icon: Icons.event_seat),
                          StatCard(label: 'Occupied', value: '${provider.occupied}', icon: Icons.person),
                          StatCard(label: 'Maintenance', value: '${provider.maintenance}', icon: Icons.build_outlined),
                          StatCard(
                            label: "Today's Revenue",
                            value: CurrencyFormatter.format(provider.todaysRevenue),
                            icon: Icons.trending_up,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TodaysActivityCard(
                        checkins: provider.todaysCheckins,
                        checkouts: provider.todaysCheckouts,
                        reservations: provider.todaysReservations,
                        pendingPayments: provider.pendingPayments,
                      ),
                      const SizedBox(height: 20),
                      const Text('Room Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      RoomStatusGrid(
                        available: provider.available,
                        reserved: provider.reserved,
                        occupied: provider.occupied,
                        maintenance: provider.maintenance,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
