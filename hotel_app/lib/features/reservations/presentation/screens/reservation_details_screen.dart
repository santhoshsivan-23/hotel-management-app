import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../food_orders/presentation/screens/new_order_screen.dart';
import '../../../room_services/presentation/screens/new_service_request_screen.dart';
import '../../../payments_billing/presentation/screens/take_payment_screen.dart';
import '../../../payments_billing/presentation/screens/invoice_screen.dart';
import '../../../checkin_checkout/presentation/screens/checkout_screen.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../widgets/reservation_status_chip.dart';

class ReservationDetailsScreen extends StatefulWidget {
  const ReservationDetailsScreen({super.key, required this.bookingUuid});
  final String bookingUuid;

  @override
  State<ReservationDetailsScreen> createState() => _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  BookingModel? _booking;
  Map<String, double>? _bill;
  bool _loading = true;

  late final BookingRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = BookingRepository(context.read<AppDatabase>());
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final booking = await _repository.findByUuid(widget.bookingUuid);
    final bill = booking == null ? null : await _repository.runningBill(booking);
    if (!mounted) return;
    setState(() {
      _booking = booking;
      _bill = bill;
      _loading = false;
    });
  }

  Future<void> _checkin() async {
    await _repository.checkin(widget.bookingUuid);
    await _load();
  }

  Future<void> _cancel() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancel Reservation',
      message: 'Cancel this reservation? The room will become available again.',
      isDestructive: true,
    );
    if (confirmed) {
      await _repository.cancel(widget.bookingUuid);
      await _load();
    }
  }

  Future<void> _reopen() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reopen Stay for Adjustments',
      message: 'Reopen this stay? This will allow adding post-stay adjustments and charges.',
    );
    if (confirmed) {
      await _repository.reopen(widget.bookingUuid);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingIndicator());
    final booking = _booking;
    if (booking == null) {
      return const Scaffold(body: Center(child: Text('Booking not found')));
    }
    final bill = _bill!;
    final isCheckedOut = booking.status == 'CHECKED_OUT';
    final isCancelled = booking.status == 'CANCELLED';
    final canAddTransactions = !isCheckedOut && !isCancelled;

    return Scaffold(
      appBar: AppBar(
        title: Text(booking.bookingNumber ?? 'Pending booking number'),
        actions: [
          if (booking.isPending)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: Icon(Icons.cloud_upload_outlined, size: 20)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                ReservationStatusChip(status: booking.status),
                const SizedBox(width: 8),
                Text('Room ${booking.roomNumber ?? booking.roomId}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (isCheckedOut) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 20, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Stay is Closed / Checked Out. Additional transactions are disabled.',
                        style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _sectionTitle('Guest Information'),
            _infoRow('Name', booking.guestName ?? '-'),
            _infoRow('Mobile', booking.guestMobile ?? '-'),
            const Divider(height: 32),
            _sectionTitle('Stay Information'),
            _infoRow('Check-in', AppDateUtils.formatDisplayDate(booking.checkIn)),
            _infoRow('Check-out', AppDateUtils.formatDisplayDate(booking.checkOut)),
            _infoRow('Nights', '${booking.nights}'),
            _infoRow('Guests', '${booking.adults} adults, ${booking.children} children'),
            const Divider(height: 32),
            _sectionTitle('Running Bill'),
            _infoRow('Room Charges', CurrencyFormatter.format(bill['roomCharges'])),
            _infoRow('Food Charges', CurrencyFormatter.format(bill['foodCharges'])),
            _infoRow('Service Charges', CurrencyFormatter.format(bill['serviceCharges'])),
            _infoRow('Discount', '- ${CurrencyFormatter.format(bill['discount'])}'),
            _infoRow('Tax', CurrencyFormatter.format(bill['tax'])),
            _infoRow('Grand Total', CurrencyFormatter.format(bill['grandTotal']), bold: true),
            _infoRow('Paid', CurrencyFormatter.format(bill['paidAmount'])),
            _infoRow('Balance', CurrencyFormatter.format(bill['balance']),
                bold: true, color: (bill['balance'] ?? 0) > 0 ? AppColors.error : AppColors.success),
            const Divider(height: 32),
            _sectionTitle('Actions'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (booking.status == 'CONFIRMED')
                  ElevatedButton.icon(onPressed: _checkin, icon: const Icon(Icons.login), label: const Text('Check-in')),
                if (booking.status == 'CHECKED_IN')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Check-out'),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CheckoutScreen(bookingUuid: booking.uuid)),
                      );
                      _load();
                    },
                  ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.restaurant),
                  label: const Text('Add Food Order'),
                  onPressed: !canAddTransactions
                      ? null
                      : () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => NewOrderScreen(
                              bookingUuid: booking.uuid,
                              roomId: booking.roomId,
                              guestUuid: booking.guestUuid,
                            ),
                          ));
                          _load();
                        },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.room_service),
                  label: const Text('Add Service'),
                  onPressed: !canAddTransactions
                      ? null
                      : () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => NewServiceRequestScreen(
                              bookingUuid: booking.uuid,
                              roomId: booking.roomId,
                              guestUuid: booking.guestUuid,
                            ),
                          ));
                          _load();
                        },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.payments),
                  label: const Text('Add Payment'),
                  onPressed: !canAddTransactions
                      ? null
                      : () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => TakePaymentScreen(bookingUuid: booking.uuid, suggestedAmount: bill['balance']),
                          ));
                          _load();
                        },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Print Invoice'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InvoiceScreen(bookingUuid: booking.uuid)),
                  ),
                ),
                if (isCheckedOut)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Reopen Stay for Adjustments'),
                    onPressed: _reopen,
                  ),
                if (booking.status == 'PENDING' || booking.status == 'CONFIRMED')
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    onPressed: _cancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );

  Widget _infoRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color),
          ),
        ],
      ),
    );
  }
}
