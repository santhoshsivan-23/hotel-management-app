import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/utils/validators.dart';
import '../../data/models/guest_model.dart';
import '../../data/repositories/guest_repository.dart';

class AddEditGuestScreen extends StatefulWidget {
  const AddEditGuestScreen({super.key, this.existing});
  final GuestModel? existing;

  @override
  State<AddEditGuestScreen> createState() => _AddEditGuestScreenState();
}

class _AddEditGuestScreenState extends State<AddEditGuestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _idProofType;
  late final TextEditingController _idProofNumber;
  late final TextEditingController _address;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _name = TextEditingController(text: g?.name ?? '');
    _mobile = TextEditingController(text: g?.mobile ?? '');
    _email = TextEditingController(text: g?.email ?? '');
    _idProofType = TextEditingController(text: g?.idProofType ?? '');
    _idProofNumber = TextEditingController(text: g?.idProofNumber ?? '');
    _address = TextEditingController(text: g?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _idProofType.dispose();
    _idProofNumber.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final repository = GuestRepository(context.read<AppDatabase>());
      if (widget.existing == null) {
        await repository.create(
          name: _name.text.trim(),
          mobile: _mobile.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          idProofType: _idProofType.text.trim().isEmpty ? null : _idProofType.text.trim(),
          idProofNumber: _idProofNumber.text.trim().isEmpty ? null : _idProofNumber.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        );
      } else {
        await repository.update(
          widget.existing!.uuid,
          name: _name.text.trim(),
          mobile: _mobile.text.trim(),
          email: _email.text.trim(),
          idProofType: _idProofType.text.trim(),
          idProofNumber: _idProofNumber.text.trim(),
          address: _address.text.trim(),
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Guest' : 'New Guest')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => Validators.required(v, field: 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile'),
                validator: Validators.mobile,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (optional)'),
                validator: Validators.emailOptional,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _idProofType,
                decoration: const InputDecoration(labelText: 'ID Proof Type (e.g. Passport, Aadhaar)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _idProofNumber,
                decoration: const InputDecoration(labelText: 'ID Proof Number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEdit ? 'Save Changes' : 'Add Guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
