import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../data/repositories/room_repository.dart';

class AddEditRoomScreen extends StatefulWidget {
  const AddEditRoomScreen({super.key});

  @override
  State<AddEditRoomScreen> createState() => _AddEditRoomScreenState();
}

class _AddEditRoomScreenState extends State<AddEditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumber = TextEditingController();
  final _floor = TextEditingController();
  final _capacity = TextEditingController(text: '2');
  final _price = TextEditingController();

  List<Map<String, dynamic>> _roomTypes = [];
  int? _selectedRoomTypeId;
  bool _loadingTypes = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoomTypes();
  }

  Future<void> _loadRoomTypes() async {
    try {
      final response = await context.read<ApiClient>().dio.get(ApiEndpoints.roomTypes);
      setState(() {
        _roomTypes = List<Map<String, dynamic>>.from(response.data as List);
        if (_roomTypes.isNotEmpty) {
          final first = _roomTypes.first;
          _selectedRoomTypeId = first['id'] as int;
          _applyRoomTypeDefaults(first);
        }
        _loadingTypes = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Connect to the internet to load room types';
        _loadingTypes = false;
      });
    }
  }

  void _applyRoomTypeDefaults(Map<String, dynamic> roomType) {
    if (roomType['default_price'] != null) {
      final priceNum = roomType['default_price'];
      if (priceNum is num) {
        _price.text = priceNum % 1 == 0 ? priceNum.toInt().toString() : priceNum.toString();
      } else {
        _price.text = priceNum.toString();
      }
    }
    if (roomType['default_capacity'] != null) {
      _capacity.text = roomType['default_capacity'].toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomTypeId == null) {
      setState(() => _error = 'Please select a Room Type. If none are listed, ensure room types are configured in Settings.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repository = RoomRepository(
        database: context.read<AppDatabase>(),
        apiClient: context.read<ApiClient>(),
      );

      await repository.create(
        roomNumber: _roomNumber.text.trim(),
        roomTypeId: _selectedRoomTypeId!,
        floor: _floor.text.trim().isEmpty ? null : _floor.text.trim(),
        capacity: int.parse(_capacity.text.trim()),
        price: double.parse(_price.text.trim()),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not create room: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Room')),
      body: _loadingTypes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _roomNumber,
                      decoration: const InputDecoration(labelText: 'Room Number'),
                      validator: (v) => Validators.required(v, field: 'Room number'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _selectedRoomTypeId,
                      decoration: const InputDecoration(labelText: 'Room Type'),
                      items: _roomTypes.map((rt) {
                        final price = rt['default_price'] as num?;
                        final priceStr = price != null ? ' (Default: ${CurrencyFormatter.format(price)})' : '';
                        return DropdownMenuItem(
                          value: rt['id'] as int,
                          child: Text('${rt['name']}$priceStr'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedRoomTypeId = v;
                          final selected = _roomTypes.firstWhere((rt) => rt['id'] == v, orElse: () => {});
                          if (selected.isNotEmpty) {
                            _applyRoomTypeDefaults(selected);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _floor,
                      decoration: const InputDecoration(labelText: 'Floor'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _capacity,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Capacity'),
                      validator: (v) => Validators.positiveInteger(v, field: 'Capacity'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price per night',
                        helperText: 'Defaults to Room Type price. You can edit this for custom pricing.',
                      ),
                      validator: (v) => Validators.positiveNumber(v, field: 'Price'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Add Room'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
