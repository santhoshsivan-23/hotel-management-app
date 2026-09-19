import 'package:flutter/material.dart';
import '../../../../../core/config/api_endpoints.dart';
import '../../../../../core/db/tables/payment_methods_table.dart';
import '../../../_shared/reference_crud_screen.dart';
import '../../../_shared/reference_field.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReferenceCrudScreen(
      title: 'Payment Methods',
      endpoint: ApiEndpoints.paymentMethods,
      localTable: PaymentMethodsTable.tableName,
      fields: [
        ReferenceField(key: 'name', label: 'Name'),
        ReferenceField(key: 'active', label: 'Active', type: ReferenceFieldType.boolean, required: false),
      ],
    );
  }
}
