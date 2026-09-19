import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import 'reference_data_repository.dart';
import 'reference_field.dart';

/// Generic "list + add/edit form" screen for simple reference-data
/// entities. Room Types, Amenities, Service Types, Taxes and Payment
/// Methods all instantiate this with their own endpoint/table/fields
/// rather than each hand-rolling the same list-and-dialog UI.
class ReferenceCrudScreen extends StatefulWidget {
  const ReferenceCrudScreen({
    super.key,
    required this.title,
    required this.endpoint,
    required this.localTable,
    required this.fields,
  });

  final String title;
  final String endpoint;
  final String localTable;
  final List<ReferenceField> fields;

  @override
  State<ReferenceCrudScreen> createState() => _ReferenceCrudScreenState();
}

class _ReferenceCrudScreenState extends State<ReferenceCrudScreen> {
  late final ReferenceDataRepository _repository;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _isLive = true;

  @override
  void initState() {
    super.initState();
    _repository = ReferenceDataRepository(
      apiClient: context.read<ApiClient>(),
      database: context.read<AppDatabase>(),
      endpoint: widget.endpoint,
      localTable: widget.localTable,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _repository.list();
    if (!mounted) return;
    setState(() {
      _items = result.items;
      _isLive = result.isLive;
      _loading = false;
    });
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    if (!_isLive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect to the internet to make changes here')),
      );
      return;
    }

    final controllers = <String, TextEditingController>{};
    final switches = <String, bool>{};
    for (final field in widget.fields) {
      if (field.type == ReferenceFieldType.boolean) {
        switches[field.key] = existing == null ? true : (existing[field.key] == 1 || existing[field.key] == true);
      } else {
        controllers[field.key] = TextEditingController(text: existing?[field.key]?.toString() ?? '');
      }
    }

    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add ${widget.title}' : 'Edit ${widget.title}'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.fields.map((field) {
                  if (field.type == ReferenceFieldType.boolean) {
                    return SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(field.label),
                      value: switches[field.key] ?? true,
                      onChanged: (v) => setDialogState(() => switches[field.key] = v),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextFormField(
                      controller: controllers[field.key],
                      keyboardType:
                          field.type == ReferenceFieldType.number ? TextInputType.number : TextInputType.text,
                      decoration: InputDecoration(labelText: field.label),
                      validator: field.required
                          ? (v) => (v == null || v.trim().isEmpty) ? '${field.label} is required' : null
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final data = <String, dynamic>{};
    for (final field in widget.fields) {
      if (field.type == ReferenceFieldType.boolean) {
        data[field.key] = switches[field.key];
      } else if (field.type == ReferenceFieldType.number) {
        data[field.key] = num.tryParse(controllers[field.key]!.text.trim()) ?? 0;
      } else {
        data[field.key] = controllers[field.key]!.text.trim();
      }
    }

    try {
      if (existing == null) {
        await _repository.create(data);
      } else {
        await _repository.update(existing['id'] as int, data);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete ${widget.title}',
      message: 'Delete "${item['name']}"? This cannot be undone.',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      await _repository.delete(item['id'] as int);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          if (!_isLive)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                "You're offline - showing the last synced copy. Connect to make changes.",
                style: TextStyle(fontSize: 12),
              ),
            ),
          Expanded(
            child: _loading
                ? const LoadingIndicator()
                : _items.isEmpty
                    ? EmptyState(message: 'No ${widget.title.toLowerCase()} yet', icon: Icons.list_alt)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final subtitleFields = widget.fields
                                .where((f) => f.showInList && f.key != 'name')
                                .map((f) => '${f.label}: ${item[f.key]}')
                                .join(' • ');
                            return ListTile(
                              title: Text(item['name']?.toString() ?? ''),
                              subtitle: subtitleFields.isEmpty ? null : Text(subtitleFields),
                              trailing: _isLive
                                  ? PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') _openForm(existing: item);
                                        if (value == 'delete') _delete(item);
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                                      ],
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
