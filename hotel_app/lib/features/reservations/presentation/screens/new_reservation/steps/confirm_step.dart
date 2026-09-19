import 'package:flutter/material.dart';
import '../../../../../../core/theme/colors.dart';
import '../../../../../../core/utils/currency_formatter.dart';
import '../../../../../../core/utils/date_utils.dart';
import '../../../../data/models/booking_model.dart';
import '../reservation_wizard_state.dart';

/// Final review before the booking is written to the local database.
/// Nothing here talks to the network - tapping "Confirm Booking" (in the
/// wizard shell) creates the guest (if new) and the booking locally,
/// exactly like every other offline-capable write in this app.
class ConfirmStep extends StatelessWidget {
  const ConfirmStep({super.key, required this.state, required this.pricing});
  final ReservationWizardState state;
  final PricingBreakdown? pricing;

  @override
  Widget build(BuildContext context) {
    final guestLabel = state.existingGuest?.name ?? state.newGuestName ?? '-';
    final guestMobile = state.existingGuest?.mobile ?? state.newGuestMobile ?? '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Confirm Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Guest', '$guestLabel ($guestMobile)'),
                  _row('Room', state.selectedRoom == null
                      ? '-'
                      : '${state.selectedRoom!.roomTypeName ?? ''} - ${state.selectedRoom!.roomNumber}'),
                  _row('Check-in', state.checkIn == null ? '-' : AppDateUtils.formatDisplayDate(state.checkIn!)),
                  _row('Check-out', state.checkOut == null ? '-' : AppDateUtils.formatDisplayDate(state.checkOut!)),
                  _row('Guests', '${state.adults} adults, ${state.children} children'),
                  const Divider(height: 24),
                  _row('Room Total', CurrencyFormatter.format(pricing?.roomTotal)),
                  _row('Discount', '- ${CurrencyFormatter.format(state.discount)}'),
                  _row('Tax', CurrencyFormatter.format(pricing?.taxAmount)),
                  _row('Grand Total', CurrencyFormatter.format(pricing?.grandTotal), bold: true),
                  _row('Advance Paid', CurrencyFormatter.format(state.advancePaid)),
                  _row('Balance Due',
                      CurrencyFormatter.format((pricing?.grandTotal ?? 0) - state.advancePaid),
                      bold: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
