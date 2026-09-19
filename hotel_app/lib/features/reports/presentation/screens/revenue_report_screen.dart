import 'package:flutter/material.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../_shared/report_table.dart';

class RevenueReportScreen extends StatelessWidget {
  const RevenueReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportTable(
      endpoint: ApiEndpoints.reportRevenue,
      isSingleObject: true,
      columns: [
        ('Room Revenue', 'room_revenue', (v) => CurrencyFormatter.format(v as num?)),
        ('Food Revenue', 'food_revenue', (v) => CurrencyFormatter.format(v as num?)),
        ('Service Revenue', 'service_revenue', (v) => CurrencyFormatter.format(v as num?)),
        ('Discount', 'discount', (v) => CurrencyFormatter.format(v as num?)),
        ('Tax', 'tax', (v) => CurrencyFormatter.format(v as num?)),
        ('Total Revenue', 'total_revenue', (v) => CurrencyFormatter.format(v as num?)),
      ],
    );
  }
}
