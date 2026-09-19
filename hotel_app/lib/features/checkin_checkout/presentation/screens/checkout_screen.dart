import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/daos/housekeeping_dao.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../payments_billing/data/repositories/payment_repository.dart';
import '../../../reservations/data/models/booking_model.dart';
import '../../../reservations/data/repositories/booking_repository.dart';

/// "System collects all charges -> Final Amount - Amount Already Paid =
/// Balance -> Collect balance -> Generate invoice -> Complete checkout."
/// Entirely local: the invoice PDF/number itself is generated server-side
/// once this checkout syncs, but the room flips to DIRTY and a
/// housekeeping task is queued immediately, exactly like the backend does
/// synchronously - see checkout in bookings.controller.js for parity.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.bookingUuid});
  final String bookingUuid;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final BookingRepository _bookingRepository;
  late final PaymentRepository _paymentRepository;
  BookingModel? _booking;
  Map<String, double>? _bill;
  bool _loading = true;
  bool _processing = false;
  final _paymentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final db = context.read<AppDatabase>();
    _bookingRepository = BookingRepository(db);
    _paymentRepository = PaymentRepository(db);
    _load();
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final booking = await _bookingRepository.findByUuid(widget.bookingUuid);
    final bill = booking == null ? null : await _bookingRepository.runningBill(booking);
    if (!mounted) return;
    setState(() {
      _booking = booking;
      _bill = bill;
      _loading = false;
      _paymentController.text = (bill?['balance'] ?? 0) > 0 ? bill!['balance']!.toStringAsFixed(0) : '';
    });
  }

  Future<void> _collectBalanceIfAny() async {
    final amount = double.tryParse(_paymentController.text.trim()) ?? 0;
    if (amount > 0) {
      await _paymentRepository.create(bookingUuid: widget.bookingUuid, amount: amount, method: 'Cash');
    }
  }

  Future<void> _completeCheckout() async {
    setState(() => _processing = true);
    await _collectBalanceIfAny();
    await _bookingRepository.checkout(widget.bookingUuid);

    // Room -> DIRTY, and a housekeeping task is queued, mirroring the
    // backend's synchronous OCCUPIED -> DIRTY -> housekeeping_tasks flow.
    final db = context.read<AppDatabase>();
    await db.database.then((d) => d.update(
          'rooms',
          {'status': 'DIRTY'},
          where: 'id = ?',
          whereArgs: [_booking!.roomId],
        ));
    await HousekeepingDao(db).insertForRoom({
      'uuid': UuidGenerator.generate(),
      'room_id': _booking!.roomId,
      'status': 'DIRTY',
      'sync_status': 'PENDING',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked out - invoice will finalize once synced')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final bill = _bill;
    if (_booking == null || bill == null) {
      return const Scaffold(body: Center(child: Text('Booking not found')));
    }

    final balance = bill['balance'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Check-out')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Final Bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _row('Room Charges', bill['roomCharges']),
          _row('Food Orders', bill['foodCharges']),
          _row('Room Services', bill['serviceCharges']),
          _row('Discount', -(bill['discount'] ?? 0)),
          _row('Tax', bill['tax']),
          const Divider(),
          _row('Grand Total', bill['grandTotal'], bold: true),
          _row('Already Paid', bill['paidAmount']),
          _row('Balance', balance, bold: true, color: balance > 0 ? AppColors.error : AppColors.success),
          if (balance > 0) ...[
            const SizedBox(height: 16),
            const Text('Collect Balance', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _paymentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount to collect now'),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _processing ? null : _completeCheckout,
            child: _processing
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Complete Check-out'),
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
          Text(
            CurrencyFormatter.format(value),
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color),
          ),
        ],
      ),
    );
  }
}
