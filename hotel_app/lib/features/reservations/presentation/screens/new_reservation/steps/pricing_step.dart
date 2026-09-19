import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/db/app_database.dart';
import '../../../../../../core/theme/colors.dart';
import '../../../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../data/repositories/booking_repository.dart';
import '../reservation_wizard_state.dart';

class PricingStep extends StatefulWidget {
  const PricingStep({super.key, required this.state, required this.onChanged});
  final ReservationWizardState state;
  final VoidCallback onChanged;

  @override
  State<PricingStep> createState() => _PricingStepState();
}

class _PricingStepState extends State<PricingStep> {
  late final BookingRepository _repository;
  final _discountController = TextEditingController(text: '0');
  PricingBreakdown? _pricing;

  @override
  void initState() {
    super.initState();
    _repository = BookingRepository(context.read<AppDatabase>());
    _discountController.text = widget.state.discount.toStringAsFixed(0);
    _recalculate();
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _recalculate() async {
    final room = widget.state.selectedRoom;
    if (room == null || widget.state.checkIn == null || widget.state.checkOut == null) return;

    final discount = double.tryParse(_discountController.text.trim()) ?? 0;
    widget.state.discount = discount;

    final pricing = await _repository.calculatePricing(
      roomRate: room.price,
      checkIn: widget.state.checkIn!,
      checkOut: widget.state.checkOut!,
      discount: discount,
    );
    if (mounted) setState(() => _pricing = pricing);
    widget.state.pricing = pricing;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final pricing = _pricing;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Pricing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (pricing == null)
            const CircularProgressIndicator()
          else ...[
            _row('Room Rate', CurrencyFormatter.format(widget.state.selectedRoom?.price)),
            _row('Number of Nights', '${pricing.nights}'),
            _row('Room Total', CurrencyFormatter.format(pricing.roomTotal)),
            const SizedBox(height: 12),
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Discount'),
              onChanged: (_) => _recalculate(),
            ),
            const SizedBox(height: 12),
            _row('Tax (${pricing.taxPercent.toStringAsFixed(1)}%)', CurrencyFormatter.format(pricing.taxAmount)),
            const Divider(height: 24),
            _row('Grand Total', CurrencyFormatter.format(pricing.grandTotal), bold: true),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: bold ? 18 : 14)),
        ],
      ),
    );
  }
}
