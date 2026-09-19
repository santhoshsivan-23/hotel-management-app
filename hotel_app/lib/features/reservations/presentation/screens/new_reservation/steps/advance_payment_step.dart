import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/db/app_database.dart';
import '../../../../../../core/db/tables/payment_methods_table.dart';
import '../../../../../../core/theme/colors.dart';
import '../../../../../../core/utils/currency_formatter.dart';
import '../reservation_wizard_state.dart';

class AdvancePaymentStep extends StatefulWidget {
  const AdvancePaymentStep({super.key, required this.state, required this.onChanged, required this.grandTotal});
  final ReservationWizardState state;
  final VoidCallback onChanged;
  final double grandTotal;

  @override
  State<AdvancePaymentStep> createState() => _AdvancePaymentStepState();
}

class _AdvancePaymentStepState extends State<AdvancePaymentStep> {
  final _amountController = TextEditingController(text: '0');
  List<Map<String, dynamic>> _methods = [];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.state.advancePaid.toStringAsFixed(0);
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    final rows = await context
        .read<AppDatabase>()
        .getReferenceRows(PaymentMethodsTable.tableName, where: 'active = 1', orderBy: 'name ASC');
    if (mounted) {
      setState(() => _methods = rows.isEmpty ? [{'name': 'Cash'}, {'name': 'Card'}, {'name': 'UPI'}] : rows);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final advance = double.tryParse(_amountController.text.trim()) ?? 0;
    final balance = widget.grandTotal - advance;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Advance Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Total: ${CurrencyFormatter.format(widget.grandTotal)}', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Advance Amount (optional)'),
            onChanged: (v) {
              widget.state.advancePaid = double.tryParse(v.trim()) ?? 0;
              setState(() {});
              widget.onChanged();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: widget.state.paymentMethod,
            decoration: const InputDecoration(labelText: 'Payment Method'),
            items: _methods.map((m) => DropdownMenuItem(value: m['name'] as String, child: Text(m['name'] as String))).toList(),
            onChanged: (v) {
              if (v != null) {
                widget.state.paymentMethod = v;
                widget.onChanged();
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Balance: ${CurrencyFormatter.format(balance)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: balance > 0 ? AppColors.warning : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
