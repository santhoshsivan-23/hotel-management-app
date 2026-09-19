import 'package:flutter/material.dart';
import '../../../../../../core/utils/date_utils.dart';
import '../reservation_wizard_state.dart';

class StayDetailsStep extends StatefulWidget {
  const StayDetailsStep({super.key, required this.state, required this.onChanged});
  final ReservationWizardState state;
  final VoidCallback onChanged;

  @override
  State<StayDetailsStep> createState() => _StayDetailsStepState();
}

class _StayDetailsStepState extends State<StayDetailsStep> {
  Future<void> _pickCheckIn() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.state.checkIn ?? now,
      firstDate: AppDateUtils.startOfDay(now),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        widget.state.checkIn = picked;
        if (widget.state.checkOut != null && !widget.state.checkOut!.isAfter(picked)) {
          widget.state.checkOut = picked.add(const Duration(days: 1));
        }
      });
      widget.onChanged();
    }
  }

  Future<void> _pickCheckOut() async {
    final base = widget.state.checkIn ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.state.checkOut ?? base.add(const Duration(days: 1)),
      firstDate: base.add(const Duration(days: 1)),
      lastDate: base.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => widget.state.checkOut = picked);
      widget.onChanged();
    }
  }

  Widget _counter(String label, int value, ValueChanged<int> onChanged, {int min = 0}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => onChanged(value + 1)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Stay Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Check-in'),
            subtitle: Text(widget.state.checkIn == null
                ? 'Select date'
                : AppDateUtils.formatDisplayDate(widget.state.checkIn!)),
            onTap: _pickCheckIn,
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Check-out'),
            subtitle: Text(widget.state.checkOut == null
                ? 'Select date'
                : AppDateUtils.formatDisplayDate(widget.state.checkOut!)),
            onTap: widget.state.checkIn == null ? null : _pickCheckOut,
          ),
          const Divider(),
          const SizedBox(height: 8),
          _counter('Adults', widget.state.adults, (v) {
            setState(() => widget.state.adults = v);
            widget.onChanged();
          }, min: 1),
          const SizedBox(height: 8),
          _counter('Children', widget.state.children, (v) {
            setState(() => widget.state.children = v);
            widget.onChanged();
          }),
        ],
      ),
    );
  }
}
