import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/tables/service_types_table.dart';
import '../../data/repositories/service_request_repository.dart';

/// "Room / Guest / Booking / Service / Quantity / Price / Notes" - room,
/// guest and booking are already known from the reservation this request
/// is being placed against.
class NewServiceRequestScreen extends StatefulWidget {
  const NewServiceRequestScreen({super.key, required this.bookingUuid, required this.roomId, required this.guestUuid});
  final String bookingUuid;
  final int roomId;
  final String guestUuid;

  @override
  State<NewServiceRequestScreen> createState() => _NewServiceRequestScreenState();
}

class _NewServiceRequestScreenState extends State<NewServiceRequestScreen> {
  List<Map<String, dynamic>> _serviceTypes = [];
  int? _selectedServiceTypeId;
  int _quantity = 1;
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadServiceTypes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceTypes() async {
    final rows = await context
        .read<AppDatabase>()
        .getReferenceRows(ServiceTypesTable.tableName, where: 'active = 1', orderBy: 'name ASC');
    if (mounted) {
      setState(() {
        _serviceTypes = rows;
        _selectedServiceTypeId = rows.isNotEmpty ? rows.first['id'] as int : null;
      });
    }
  }

  Map<String, dynamic>? get _selectedServiceType {
    for (final s in _serviceTypes) {
      if (s['id'] == _selectedServiceTypeId) return s;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_selectedServiceTypeId == null) return;
    setState(() => _saving = true);

    final unitPrice = (_selectedServiceType?['price'] as num?)?.toDouble() ?? 0;
    final repository = ServiceRequestRepository(context.read<AppDatabase>());
    await repository.create(
      bookingUuid: widget.bookingUuid,
      roomId: widget.roomId,
      guestUuid: widget.guestUuid,
      serviceTypeId: _selectedServiceTypeId!,
      quantity: _quantity,
      unitPrice: unitPrice,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service request added to the room bill')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Service Request')),
      body: _serviceTypes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    value: _selectedServiceTypeId,
                    decoration: const InputDecoration(labelText: 'Service'),
                    items: _serviceTypes
                        .map((s) => DropdownMenuItem(value: s['id'] as int, child: Text(s['name'] as String)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedServiceTypeId = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                          ),
                          Text('$_quantity', style: const TextStyle(fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes (optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Add Service Request'),
                  ),
                ],
              ),
            ),
    );
  }
}
