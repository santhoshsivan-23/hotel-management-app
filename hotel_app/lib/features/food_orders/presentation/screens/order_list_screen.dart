import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../routes/app_router.dart';
import '../../providers/food_order_provider.dart';
import 'order_details_screen.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  static const _statusFilters = [null, 'NEW', 'ACCEPTED', 'PREPARING', 'READY', 'DELIVERED', 'COMPLETED'];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FoodOrderProvider(context.read<AppDatabase>())..load(),
      child: Consumer<FoodOrderProvider>(
        builder: (context, provider, _) => AppScaffold(
          title: 'In-Room Orders',
          currentRoute: AppRoutes.foodOrders,
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
                    return ChoiceChip(
                      label: Text(status ?? 'All'),
                      selected: provider.statusFilter == status,
                      onSelected: (_) => provider.setStatusFilter(status),
                    );
                  },
                ),
              ),
              Expanded(
                child: provider.loading
                    ? const LoadingIndicator()
                    : provider.orders.isEmpty
                        ? const EmptyState(message: 'No food orders yet', icon: Icons.restaurant_outlined)
                        : RefreshIndicator(
                            onRefresh: provider.load,
                            child: ListView.separated(
                              itemCount: provider.orders.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final order = provider.orders[index];
                                return ListTile(
                                  title: Text('Room ${order.roomNumber ?? order.roomId}'),
                                  subtitle: Text('Order ${order.uuid.substring(0, 8)}'),
                                  trailing: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.statusColor(order.status),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(order.status,
                                            style: const TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(CurrencyFormatter.format(order.totalAmount), style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderUuid: order.uuid)),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
