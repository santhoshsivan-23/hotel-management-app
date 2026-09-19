import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/db/app_database.dart';
import '../../../../../guests/data/repositories/guest_repository.dart';
import '../reservation_wizard_state.dart';

/// "Search Existing Guest OR Create New Guest" - both paths write nothing
/// until the final Confirm step; this step only picks/fills the guest.
class GuestStep extends StatefulWidget {
  const GuestStep({super.key, required this.state, required this.onChanged});
  final ReservationWizardState state;
  final VoidCallback onChanged;

  @override
  State<GuestStep> createState() => _GuestStepState();
}

class _GuestStepState extends State<GuestStep> {
  late final GuestRepository _repository;
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  List<dynamic> _results = [];
  bool _creatingNew = false;

  @override
  void initState() {
    super.initState();
    _repository = GuestRepository(context.read<AppDatabase>());
    if (widget.state.existingGuest != null) {
      _searchController.text = widget.state.existingGuest!.name;
    }
    _nameController.text = widget.state.newGuestName ?? '';
    _mobileController.text = widget.state.newGuestMobile ?? '';
    _emailController.text = widget.state.newGuestEmail ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    final results = await _repository.findAll(search: query);
    if (mounted) setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Guest', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Existing Guest')),
              ButtonSegment(value: true, label: Text('New Guest')),
            ],
            selected: {_creatingNew},
            onSelectionChanged: (selection) => setState(() => _creatingNew = selection.first),
          ),
          const SizedBox(height: 16),
          if (!_creatingNew) ...[
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(labelText: 'Search by name or mobile', prefixIcon: Icon(Icons.search)),
              onChanged: _search,
            ),
            const SizedBox(height: 8),
            ..._results.map((guest) {
              final selected = widget.state.existingGuest?.uuid == guest.uuid;
              return Card(
                color: selected ? Colors.blue.shade50 : null,
                child: ListTile(
                  title: Text(guest.name),
                  subtitle: Text(guest.mobile),
                  trailing: selected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () {
                    setState(() => widget.state.existingGuest = guest);
                    widget.onChanged();
                  },
                ),
              );
            }),
          ] else ...[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              onChanged: (v) {
                widget.state.newGuestName = v;
                widget.state.existingGuest = null;
                widget.onChanged();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile'),
              onChanged: (v) {
                widget.state.newGuestMobile = v;
                widget.state.existingGuest = null;
                widget.onChanged();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (optional)'),
              onChanged: (v) => widget.state.newGuestEmail = v,
            ),
          ],
        ],
      ),
    );
  }
}
