import 'package:flutter/material.dart';
import '../../../../../core/config/api_endpoints.dart';
import '../../../../../core/db/tables/amenities_table.dart';
import '../../../_shared/reference_crud_screen.dart';
import '../../../_shared/reference_field.dart';

class AmenitiesScreen extends StatelessWidget {
  const AmenitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReferenceCrudScreen(
      title: 'Amenities',
      endpoint: ApiEndpoints.amenities,
      localTable: AmenitiesTable.tableName,
      fields: [
        ReferenceField(key: 'name', label: 'Name'),
        ReferenceField(key: 'active', label: 'Active', type: ReferenceFieldType.boolean, required: false),
      ],
    );
  }
}
