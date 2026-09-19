import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../reservations/data/models/booking_model.dart';
import '../../../reservations/data/repositories/booking_repository.dart';

/// "Verify Guest, Verify ID, Verify Room, Check Payment, Confirm
/// Check-in" - a lightweight checklist in front of the actual status
/// change, so the receptionist has a moment to double check everything
/// before the room flips to OCCUPIED.
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key, required this.booking});
  final BookingModel booking;

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final Map<String, bool> _checks = {
    'Guest identity verified': false,
    'ID proof verified': false,
    'Room condition verified': false,
    'Payment / advance verified': false,
  };
  bool _saving = false;

  bool get _allChecked => _checks.values.every((v) => v);

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final repository = BookingRepository(context.read<AppDatabase>());
    await repository.checkin(widget.booking.uuid);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.guestName ?? 'Guest', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Room ${booking.roomNumber ?? booking.roomId}'),
                  Text(
                    '${AppDateUtils.formatDisplayDate(booking.checkIn)} - ${AppDateUtils.formatDisplayDate(booking.checkOut)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text('Advance paid: ${CurrencyFormatter.format(booking.advancePaid)} of '
                      '${CurrencyFormatter.format(booking.grandTotal)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ..._checks.keys.map((label) => CheckboxListTile(
                title: Text(label),
                value: _checks[label],
                onChanged: (v) => setState(() => _checks[label] = v ?? false),
              )),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_allChecked && !_saving) ? _confirm : null,
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Confirm Check-in'),
          ),
        ],
      ),
    );
  }
}
