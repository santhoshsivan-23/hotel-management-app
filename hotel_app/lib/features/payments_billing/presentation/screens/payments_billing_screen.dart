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
import '../../providers/billing_provider.dart';
import 'running_bill_screen.dart';

/// Payments & Billing landing screen - every booking still carrying a
/// balance, so front desk can see at a glance who still owes money
/// (mirrors the backend's Outstanding Report, computed locally).
class PaymentsBillingScreen extends StatelessWidget {
  const PaymentsBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BillingProvider(context.read<AppDatabase>())..load(),
      child: Consumer<BillingProvider>(
        builder: (context, provider, _) => AppScaffold(
          title: 'Payments & Billing',
          currentRoute: AppRoutes.paymentsBilling,
          body: provider.loading
              ? const LoadingIndicator()
              : provider.outstanding.isEmpty
                  ? const EmptyState(message: 'No outstanding balances', icon: Icons.check_circle_outline)
                  : RefreshIndicator(
                      onRefresh: provider.load,
                      child: ListView.separated(
                        itemCount: provider.outstanding.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = provider.outstanding[index];
                          final booking = entry.booking;
                          return ListTile(
                            title: Text(booking.guestName ?? 'Guest'),
                            subtitle: Text(
                              'Room ${booking.roomNumber ?? booking.roomId} • '
                              '${AppDateUtils.formatDisplayDate(booking.checkIn)} - ${AppDateUtils.formatDisplayDate(booking.checkOut)}',
                            ),
                            trailing: Text(
                              CurrencyFormatter.format(entry.balance),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => RunningBillScreen(bookingUuid: booking.uuid)),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}
