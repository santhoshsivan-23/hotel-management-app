import 'package:flutter/material.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../_shared/report_table.dart';

class PaymentReportScreen extends StatelessWidget {
  const PaymentReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportTable(
      endpoint: ApiEndpoints.reportPayments,
      columns: [
        ('Payment Method', 'payment_method', null),
        ('Transactions', 'transaction_count', null),
        ('Amount', 'amount', (v) => CurrencyFormatter.format(v as num?)),
      ],
    );
  }
}
