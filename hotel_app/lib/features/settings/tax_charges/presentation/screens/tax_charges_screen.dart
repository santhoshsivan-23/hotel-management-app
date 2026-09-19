import 'package:flutter/material.dart';
import '../../../../../core/config/api_endpoints.dart';
import '../../../../../core/db/tables/taxes_table.dart';
import '../../../_shared/reference_crud_screen.dart';
import '../../../_shared/reference_field.dart';

class TaxChargesScreen extends StatelessWidget {
  const TaxChargesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReferenceCrudScreen(
      title: 'Tax & Charges',
      endpoint: ApiEndpoints.taxes,
      localTable: TaxesTable.tableName,
      fields: [
        ReferenceField(key: 'name', label: 'Name'),
        ReferenceField(key: 'percentage', label: 'Percentage', type: ReferenceFieldType.number),
        ReferenceField(key: 'applicable_to', label: 'Applicable To (ROOM/FOOD/SERVICE/ALL)'),
        ReferenceField(key: 'active', label: 'Active', type: ReferenceFieldType.boolean, required: false),
      ],
    );
  }
}
