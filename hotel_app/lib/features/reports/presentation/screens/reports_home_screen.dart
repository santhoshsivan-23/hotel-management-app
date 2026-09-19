import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../routes/app_router.dart';
import '../../providers/report_provider.dart';
import 'booking_report_screen.dart';
import 'occupancy_report_screen.dart';
import 'revenue_report_screen.dart';
import 'food_sales_report_screen.dart';
import 'payment_report_screen.dart';
import 'outstanding_report_screen.dart';

/// Reports landing screen: a tab per report, matching the master spec's
/// 6 first-version reports. Every report requires connectivity - unlike
/// the operational screens, reports aggregate data across every device,
/// not just this one's local cache.
class ReportsHomeScreen extends StatelessWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportProvider(),
      child: DefaultTabController(
        length: 6,
        child: Builder(
          builder: (context) => AppScaffold(
            title: 'Reports',
            currentRoute: AppRoutes.reports,
            body: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Bookings'),
                    Tab(text: 'Occupancy'),
                    Tab(text: 'Revenue'),
                    Tab(text: 'Food Sales'),
                    Tab(text: 'Payments'),
                    Tab(text: 'Outstanding'),
                  ],
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      BookingReportScreen(),
                      OccupancyReportScreen(),
                      RevenueReportScreen(),
                      FoodSalesReportScreen(),
                      PaymentReportScreen(),
                      OutstandingReportScreen(),
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
