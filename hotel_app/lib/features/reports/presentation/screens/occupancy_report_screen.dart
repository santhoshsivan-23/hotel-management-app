import 'package:flutter/material.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../_shared/report_table.dart';

class OccupancyReportScreen extends StatelessWidget {
  const OccupancyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportTable(
      endpoint: ApiEndpoints.reportOccupancy,
      usesDateRange: false,
      isSingleObject: true,
      columns: [
        ('Total Rooms', 'total_rooms', null),
        ('Occupied', 'occupied', null),
        ('Available', 'available', null),
        ('Reserved', 'reserved', null),
        ('Cleaning', 'cleaning', null),
        ('Maintenance', 'maintenance', null),
        ('Occupancy %', 'occupancy_percent', (v) => '${v ?? 0}%'),
      ],
    );
  }
}
