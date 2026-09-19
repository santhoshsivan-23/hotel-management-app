import 'package:flutter/material.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../_shared/report_table.dart';

class BookingReportScreen extends StatelessWidget {
  const BookingReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportTable(
      endpoint: ApiEndpoints.reportBookings,
      columns: [
        ('Booking', 'booking_number', null),
        ('Guest', 'guest', null),
        ('Room', 'room_number', null),
        ('Check-in', 'check_in', null),
        ('Check-out', 'check_out', null),
        ('Amount', 'amount', (v) => CurrencyFormatter.format(v as num?)),
        ('Status', 'status', null),
      ],
    );
  }
}
