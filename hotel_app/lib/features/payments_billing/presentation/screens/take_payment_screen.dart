import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/tables/payment_methods_table.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/repositories/payment_repository.dart';

class TakePaymentScreen extends StatefulWidget {
  const TakePaymentScreen({super.key, required this.bookingUuid, this.suggestedAmount});
  final String bookingUuid;
  final double? suggestedAmount;

  @override
  State<TakePaymentScreen> createState() => _TakePaymentScreenState();
}

class _TakePaymentScreenState extends State<TakePaymentScreen> {
  late final TextEditingController _amountController;
  final _referenceController = TextEditingController();
  String _method = 'Cash';
  List<Map<String, dynamic>> _methods = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.suggestedAmount != null && widget.suggestedAmount! > 0
          ? widget.suggestedAmount!.toStringAsFixed(0)
          : '',
    );
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
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    final repository = PaymentRepository(context.read<AppDatabase>());
    await repository.create(
      bookingUuid: widget.bookingUuid,
      amount: amount,
      method: _method,
      referenceNo: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment of ${CurrencyFormatter.format(amount)} recorded')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _method,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: _methods.map((m) => DropdownMenuItem(value: m['name'] as String, child: Text(m['name'] as String))).toList(),
              onChanged: (v) => setState(() => _method = v ?? _method),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(labelText: 'Reference No. (optional)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
