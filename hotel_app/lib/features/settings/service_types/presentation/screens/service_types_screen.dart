import 'package:flutter/material.dart';
import '../../../../../core/config/api_endpoints.dart';
import '../../../../../core/db/tables/service_types_table.dart';
import '../../../_shared/reference_crud_screen.dart';
import '../../../_shared/reference_field.dart';

class ServiceTypesScreen extends StatelessWidget {
  const ServiceTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReferenceCrudScreen(
      title: 'Service Types',
      endpoint: ApiEndpoints.serviceTypes,
      localTable: ServiceTypesTable.tableName,
      fields: [
        ReferenceField(key: 'name', label: 'Name'),
        ReferenceField(key: 'category', label: 'Category', required: false),
        ReferenceField(key: 'price', label: 'Price', type: ReferenceFieldType.number),
        ReferenceField(key: 'tax_percent', label: 'Tax %', type: ReferenceFieldType.number, required: false),
        ReferenceField(key: 'active', label: 'Active', type: ReferenceFieldType.boolean, required: false),
      ],
    );
  }
}
