import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../reservations/data/models/booking_model.dart';
import '../../../reservations/data/repositories/booking_repository.dart';
import 'take_payment_screen.dart';

/// Standalone "Running Bill" view for a booking - the same numbers shown
/// inline on ReservationDetailsScreen, available as its own screen for
/// when a receptionist just wants to check/print the bill without the
/// full set of booking actions.
class RunningBillScreen extends StatefulWidget {
  const RunningBillScreen({super.key, required this.bookingUuid});
  final String bookingUuid;

  @override
  State<RunningBillScreen> createState() => _RunningBillScreenState();
}

class _RunningBillScreenState extends State<RunningBillScreen> {
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

    return Scaffold(
      appBar: AppBar(title: Text('Running Bill - ${booking.bookingNumber ?? 'Pending'}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('Room Charges', bill['roomCharges']),
          _row('Food', bill['foodCharges']),
          _row('Room Services', bill['serviceCharges']),
          const Divider(),
          _row('Subtotal', (bill['roomCharges'] ?? 0) + (bill['foodCharges'] ?? 0) + (bill['serviceCharges'] ?? 0) - (bill['discount'] ?? 0)),
          _row('Tax', bill['tax']),
          const Divider(),
          _row('Grand Total', bill['grandTotal'], bold: true),
          _row('Paid', bill['paidAmount']),
          _row('Balance', bill['balance'], bold: true, color: (bill['balance'] ?? 0) > 0 ? AppColors.error : AppColors.success),
          const SizedBox(height: 24),
          if ((bill['balance'] ?? 0) > 0)
            ElevatedButton.icon(
              icon: const Icon(Icons.payments),
              label: const Text('Take Payment'),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TakePaymentScreen(bookingUuid: booking.uuid, suggestedAmount: bill['balance'])),
                );
                _load();
              },
            ),
        ],
      ),
    );
  }

  Widget _row(String label, double? value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(CurrencyFormatter.format(value), style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
