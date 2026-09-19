import '../../../../guests/data/models/guest_model.dart';
import '../../../../rooms/data/models/room_model.dart';
import '../../../data/models/booking_model.dart';

/// Shared mutable state threaded through all six wizard steps. Each step
/// reads what it needs and calls back into NewReservationScreen to update
/// it - kept as one plain object (not a ChangeNotifier) because only the
/// wizard shell needs to react to changes, not arbitrary listeners.
class ReservationWizardState {
  DateTime? checkIn;
  DateTime? checkOut;
  int adults = 1;
  int children = 0;

  RoomModel? selectedRoom;

  GuestModel? existingGuest;
  String? newGuestName;
  String? newGuestMobile;
  String? newGuestEmail;

  double discount = 0;
  double advancePaid = 0;
  String paymentMethod = 'Cash';

  /// Set by PricingStep once it finishes recalculating; read by
  /// AdvancePaymentStep and ConfirmStep further along in the wizard.
  PricingBreakdown? pricing;

  bool get hasStayDetails => checkIn != null && checkOut != null && checkOut!.isAfter(checkIn!);
  bool get hasRoom => selectedRoom != null;
  bool get hasGuest =>
      existingGuest != null || ((newGuestName?.isNotEmpty ?? false) && (newGuestMobile?.isNotEmpty ?? false));
}
