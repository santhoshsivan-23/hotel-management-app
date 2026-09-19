import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../reservations/data/models/booking_model.dart';
import '../../../reservations/data/repositories/booking_repository.dart';

/// Read-only invoice view. The authoritative, numbered invoice
/// (INV-000123) is generated server-side once this booking's checkout
/// syncs (see invoice.service.js); until then this shows the same totals
/// computed locally, labeled clearly as a preview.
class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key, required this.bookingUuid});
  final String bookingUuid;

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  BookingModel? _booking;
  Map<String, double>? _bill;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repository = BookingRepository(context.read<AppDatabase>());
    final booking = await repository.findByUuid(widget.bookingUuid);
    final bill = booking == null ? null : await repository.runningBill(booking);
    if (mounted) {
      setState(() {
        _booking = booking;
        _bill = bill;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final bill = _bill;
    if (booking == null || bill == null) return const Scaffold(body: LoadingIndicator());

    final isFinalized = booking.bookingNumber != null && booking.status == 'CHECKED_OUT';

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isFinalized)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.syncPending.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Text(
                'Preview only - the final numbered invoice is generated once this booking syncs.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          Text(booking.bookingNumber ?? 'Pending booking number', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('${booking.guestName ?? 'Guest'} • Room ${booking.roomNumber ?? booking.roomId}'),
          Text('${AppDateUtils.formatDisplayDate(booking.checkIn)} - ${AppDateUtils.formatDisplayDate(booking.checkOut)}'),
          const Divider(height: 32),
          _row('Room Charges', bill['roomCharges']),
          _row('Food Charges', bill['foodCharges']),
          _row('Service Charges', bill['serviceCharges']),
          _row('Discount', -(bill['discount'] ?? 0)),
          _row('Tax', bill['tax']),
          const Divider(),
          _row('Grand Total', bill['grandTotal'], bold: true),
          _row('Paid Amount', bill['paidAmount']),
          _row('Balance', bill['balance'], bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, double? value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(CurrencyFormatter.format(value), style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
