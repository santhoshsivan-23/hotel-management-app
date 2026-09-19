import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../routes/app_router.dart';
import '../../providers/service_provider.dart';

class ServiceRequestListScreen extends StatelessWidget {
  const ServiceRequestListScreen({super.key});

  static const _statuses = ['REQUESTED', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'DELIVERED'];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ServiceProvider(context.read<AppDatabase>())..load(),
      child: Consumer<ServiceProvider>(
        builder: (context, provider, _) => AppScaffold(
          title: 'Room Services',
          currentRoute: AppRoutes.roomServices,
          body: Column(
            children: [
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _statuses.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final status = index == 0 ? null : _statuses[index - 1];
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
                    : provider.requests.isEmpty
                        ? const EmptyState(message: 'No service requests yet', icon: Icons.room_service_outlined)
                        : RefreshIndicator(
                            onRefresh: provider.load,
                            child: ListView.separated(
                              itemCount: provider.requests.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final request = provider.requests[index];
                                return ListTile(
                                  title: Text(request.serviceTypeName ?? 'Service #${request.serviceTypeId}'),
                                  subtitle: Text('Room ${request.roomNumber ?? request.roomId} • Qty ${request.quantity}'),
                                  trailing: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.statusColor(request.status),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(request.status, style: const TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(CurrencyFormatter.format(request.amount), style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  onTap: () => _showStatusPicker(context, request.uuid, request.status),
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

  void _showStatusPicker(BuildContext context, String uuid, String currentStatus) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _statuses
              .map((status) => ListTile(
                    title: Text(status),
                    trailing: status == currentStatus ? const Icon(Icons.check) : null,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.read<ServiceProvider>().updateStatus(uuid, status);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}
