import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../data/models/food_order_model.dart';
import '../../data/repositories/food_order_repository.dart';
import '../../providers/food_order_provider.dart';

/// Takes only the uuid (not a full model) and loads its own data,
/// including line items - the list screen's rows come from a query that
/// doesn't join items (to avoid duplicate rows per order), so this is the
/// one place that actually needs the full order with its items attached.
class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.orderUuid});
  final String orderUuid;

  static const _statuses = ['NEW', 'ACCEPTED', 'PREPARING', 'READY', 'DELIVERED', 'COMPLETED'];

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  FoodOrderModel? _order;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final order = await FoodOrderRepository(context.read<AppDatabase>()).findByUuid(widget.orderUuid);
    if (mounted) setState(() => _order = order);
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    if (order == null) {
      return const Scaffold(body: LoadingIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Order - Room ${order.roomNumber ?? order.roomId}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.statusColor(order.status), borderRadius: BorderRadius.circular(6)),
            child: Text(order.status, style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 16),
          ...order.items.map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${item.productName} x${item.quantity}'),
                subtitle: item.notes != null && item.notes!.isNotEmpty ? Text(item.notes!) : null,
                trailing: Text(CurrencyFormatter.format(item.lineTotal)),
              )),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(CurrencyFormatter.format(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: OrderDetailsScreen._statuses.map((status) {
              final isCurrent = status == order.status;
              return ChoiceChip(
                label: Text(status),
                selected: isCurrent,
                onSelected: isCurrent
                    ? null
                    : (_) async {
                        await context.read<FoodOrderProvider>().updateStatus(order.uuid, status);
                        if (context.mounted) Navigator.of(context).pop();
                      },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
