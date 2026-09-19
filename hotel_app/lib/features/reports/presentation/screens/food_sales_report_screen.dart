import 'package:flutter/material.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../_shared/report_table.dart';

class FoodSalesReportScreen extends StatelessWidget {
  const FoodSalesReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportTable(
      endpoint: ApiEndpoints.reportFoodSales,
      columns: [
        ('Product', 'product', null),
        ('Quantity', 'quantity', null),
        ('Orders', 'orders', null),
        ('Revenue', 'revenue', (v) => CurrencyFormatter.format(v as num?)),
      ],
    );
  }
}
