import 'package:flutter/material.dart';
import '../../../reservations/presentation/screens/reservation_details_screen.dart';

/// An active stay is just a CHECKED_IN booking - room, guest, dates,
/// current bill, paid/balance, and the Food Order / Room Service /
/// Payment / Change Room / Extend Stay / View Bill / Check-out actions
/// are all already exactly what ReservationDetailsScreen shows for a
/// booking in that state. Rather than duplicate that screen, this is a
/// thin, explicitly-named entry point for the Check-in/Check-out tab so
/// "Active Stays" reads naturally in navigation and analytics.
class ActiveStayScreen extends StatelessWidget {
  const ActiveStayScreen({super.key, required this.bookingUuid});
  final String bookingUuid;

  @override
  Widget build(BuildContext context) {
    return ReservationDetailsScreen(bookingUuid: bookingUuid);
  }
}
