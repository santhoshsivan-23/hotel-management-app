import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/config/api_endpoints.dart';
import '../../../../../core/db/app_database.dart';
import '../../../../../core/db/tables/hotel_settings_table.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/widgets/loading_indicator.dart';

/// Hotel Name / Logo / Address / Tax Info / Currency / Timezone /
/// Check-in-Check-out times / Invoice & Booking prefixes - a single-row
/// settings form. Reads from the live API when possible, falling back to
/// the local cache (read-only) when offline.
class HotelBusinessSettingsScreen extends StatefulWidget {
  const HotelBusinessSettingsScreen({super.key});

  @override
  State<HotelBusinessSettingsScreen> createState() => _HotelBusinessSettingsScreenState();
}

class _HotelBusinessSettingsScreenState extends State<HotelBusinessSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    for (final key in [
      'hotel_name', 'address', 'phone', 'email', 'tax_info', 'currency',
      'timezone', 'checkin_time', 'checkout_time', 'invoice_prefix', 'booking_prefix',
    ])
      key: TextEditingController(),
  };

  bool _loading = true;
  bool _isLive = true;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await context.read<ApiClient>().dio.get(ApiEndpoints.hotelSettings);
      _applyToForm(response.data as Map<String, dynamic>);
      setState(() {
        _isLive = true;
        _loading = false;
      });
    } on DioException {
      final cached = await context.read<AppDatabase>().getReferenceRows(HotelSettingsTable.tableName);
      if (cached.isNotEmpty) _applyToForm(cached.first);
      setState(() {
        _isLive = false;
        _loading = false;
      });
    }
  }

  void _applyToForm(Map<String, dynamic> data) {
    for (final key in _controllers.keys) {
      _controllers[key]!.text = data[key]?.toString() ?? '';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<ApiClient>().dio.put(
        ApiEndpoints.hotelSettings,
        data: {for (final key in _controllers.keys) key: _controllers[key]!.text.trim()},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
      }
    } on DioException catch (e) {
      if (mounted) {
        final message = (e.response?.data is Map) ? e.response?.data['message'] : 'Failed to save';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$message')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[key],
        enabled: _isLive,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hotel / Business Settings')),
      body: _loading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isLive)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        color: Colors.orange.shade100,
                        child: const Text(
                          "You're offline - showing the last synced copy. Connect to make changes.",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    _field('hotel_name', 'Hotel Name'),
                    _field('address', 'Address'),
                    _field('phone', 'Phone'),
                    _field('email', 'Email'),
                    _field('tax_info', 'Tax Information (e.g. GSTIN)'),
                    _field('currency', 'Currency (e.g. INR)'),
                    _field('timezone', 'Timezone (e.g. Asia/Kolkata)'),
                    _field('checkin_time', 'Check-in Time (e.g. 12:00 PM)'),
                    _field('checkout_time', 'Check-out Time (e.g. 11:00 AM)'),
                    _field('invoice_prefix', 'Invoice Prefix (e.g. INV)'),
                    _field('booking_prefix', 'Booking Prefix (e.g. BK)'),
                    const SizedBox(height: 12),
                    if (_isLive)
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Settings'),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
