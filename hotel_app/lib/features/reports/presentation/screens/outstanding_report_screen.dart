import 'package:flutter/material.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../_shared/report_table.dart';

class OutstandingReportScreen extends StatelessWidget {
  const OutstandingReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportTable(
      endpoint: ApiEndpoints.reportOutstanding,
      usesDateRange: false,
      columns: [
        ('Booking', 'booking', null),
        ('Guest', 'guest', null),
        ('Room', 'room', null),
        ('Total', 'total', (v) => CurrencyFormatter.format(v as num?)),
        ('Paid', 'paid', (v) => CurrencyFormatter.format(v as num?)),
        ('Balance', 'balance', (v) => CurrencyFormatter.format(v as num?)),
      ],
    );
  }
}
