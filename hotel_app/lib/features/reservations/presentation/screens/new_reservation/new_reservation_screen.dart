import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/db/app_database.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../../guests/data/repositories/guest_repository.dart';
import '../../../../payments_billing/data/repositories/payment_repository.dart';
import 'reservation_wizard_state.dart';
import 'steps/stay_details_step.dart';
import 'steps/room_search_step.dart';
import 'steps/guest_step.dart';
import 'steps/pricing_step.dart';
import 'steps/advance_payment_step.dart';
import 'steps/confirm_step.dart';

/// Step-based "New Reservation" flow, per the app spec: Stay Details ->
/// Search Available Rooms -> Guest -> Pricing -> Advance Payment ->
/// Confirm. Every step runs entirely against the local cache; the booking
/// (and a new guest, if one was created) is written to the local database
/// on Confirm - nothing is sent over the network here. It goes up next
/// time the receptionist taps "Sync Now".
class NewReservationScreen extends StatefulWidget {
  const NewReservationScreen({super.key});

  @override
  State<NewReservationScreen> createState() => _NewReservationScreenState();
}

class _NewReservationScreenState extends State<NewReservationScreen> {
  final _state = ReservationWizardState();
  final _pageController = PageController();
  int _step = 0;
  bool _saving = false;

  static const _titles = [
    'Stay Details', 'Available Rooms', 'Guest', 'Pricing', 'Advance Payment', 'Confirm',
  ];

  bool get _canGoNext {
    switch (_step) {
      case 0:
        return _state.hasStayDetails;
      case 1:
        return _state.hasRoom;
      case 2:
        return _state.hasGuest;
      case 3:
        return _state.pricing != null;
      case 4:
        return true;
      default:
        return false;
    }
  }

  void _onChanged() => setState(() {});

  Future<void> _next() async {
    if (_step < 5) {
      setState(() => _step++);
      _pageController.animateToPage(_step, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    } else {
      await _confirm();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
    _pageController.animateToPage(_step, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final database = context.read<AppDatabase>();
    final guestRepo = GuestRepository(database);
    final bookingRepo = BookingRepository(database);
    final paymentRepo = PaymentRepository(database);

    try {
      var guestUuid = _state.existingGuest?.uuid;
      guestUuid ??= (await guestRepo.create(
        name: _state.newGuestName!,
        mobile: _state.newGuestMobile!,
        email: _state.newGuestEmail,
      ))
          .uuid;

      final booking = await bookingRepo.create(
        guestUuid: guestUuid,
        roomId: _state.selectedRoom!.id,
        roomRate: _state.selectedRoom!.price,
        checkIn: _state.checkIn!,
        checkOut: _state.checkOut!,
        adults: _state.adults,
        children: _state.children,
        discount: _state.discount,
        advancePaid: _state.advancePaid,
      );

      if (_state.advancePaid > 0) {
        await paymentRepo.create(
          bookingUuid: booking.uuid,
          amount: _state.advancePaid,
          method: _state.paymentMethod,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created - it will sync automatically once online')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Reservation - ${_titles[_step]}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_step + 1) / _titles.length),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StayDetailsStep(state: _state, onChanged: _onChanged),
                RoomSearchStep(state: _state, onChanged: _onChanged),
                GuestStep(state: _state, onChanged: _onChanged),
                PricingStep(
                  state: _state,
                  onChanged: () {
                    setState(() {});
                  },
                ),
                AdvancePaymentStep(
                  state: _state,
                  onChanged: _onChanged,
                  grandTotal: _state.pricing?.grandTotal ?? 0,
                ),
                ConfirmStep(state: _state, pricing: _state.pricing),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: (_canGoNext && !_saving) ? _next : null,
                child: _saving
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_step == 5 ? 'Confirm Booking' : 'Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
