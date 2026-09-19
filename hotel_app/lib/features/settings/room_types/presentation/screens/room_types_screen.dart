import 'package:flutter/material.dart';
import '../../../../../core/config/api_endpoints.dart';
import '../../../../../core/db/tables/room_types_table.dart';
import '../../../_shared/reference_crud_screen.dart';
import '../../../_shared/reference_field.dart';

class RoomTypesScreen extends StatelessWidget {
  const RoomTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReferenceCrudScreen(
      title: 'Room Types',
      endpoint: ApiEndpoints.roomTypes,
      localTable: RoomTypesTable.tableName,
      fields: [
        ReferenceField(key: 'name', label: 'Name'),
        ReferenceField(key: 'description', label: 'Description', required: false),
        ReferenceField(key: 'default_capacity', label: 'Default Capacity', type: ReferenceFieldType.number),
        ReferenceField(key: 'default_price', label: 'Default Price', type: ReferenceFieldType.number),
        ReferenceField(key: 'active', label: 'Active', type: ReferenceFieldType.boolean, required: false),
      ],
    );
  }
}
