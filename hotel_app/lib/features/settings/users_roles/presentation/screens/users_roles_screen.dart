import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/config/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/loading_indicator.dart';

/// Users & Roles is admin-only and always requires connectivity - user
/// management is deliberately NOT part of the offline-sync surface, so
/// this screen talks to the API directly rather than through a DAO.
class UsersRolesScreen extends StatefulWidget {
  const UsersRolesScreen({super.key});

  @override
  State<UsersRolesScreen> createState() => _UsersRolesScreenState();
}

class _UsersRolesScreenState extends State<UsersRolesScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _roles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>().dio;
      final usersRes = await api.get(ApiEndpoints.users);
      final rolesRes = await api.get(ApiEndpoints.roles);
      setState(() {
        _users = List<Map<String, dynamic>>.from(usersRes.data as List);
        _roles = List<Map<String, dynamic>>.from(rolesRes.data as List);
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = (e.response?.data is Map)
            ? (e.response?.data['message'] as String? ?? 'Failed to load users')
            : 'Could not reach the server - connect to the internet to manage users';
        _loading = false;
      });
    }
  }

  Future<void> _openAddUserForm() async {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String? selectedRole = _roles.isNotEmpty ? _roles.first['name'] as String : null;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add User'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: mobileController,
                    decoration: const InputDecoration(labelText: 'Mobile'),
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: _roles
                        .map((r) => DropdownMenuItem(value: r['name'] as String, child: Text(r['name'] as String)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedRole = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      await context.read<ApiClient>().dio.post(ApiEndpoints.users, data: {
        'name': nameController.text.trim(),
        'mobile': mobileController.text.trim(),
        'email': emailController.text.trim(),
        'username': usernameController.text.trim(),
        'password': passwordController.text,
        'role': selectedRole,
      });
      await _load();
    } on DioException catch (e) {
      if (mounted) {
        final message = (e.response?.data is Map) ? e.response?.data['message'] : 'Failed to create user';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$message')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users & Roles')),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? EmptyState(message: _error!, icon: Icons.wifi_off, actionLabel: 'Retry', onAction: _load)
              : _users.isEmpty
                  ? const EmptyState(message: 'No users yet', icon: Icons.people_outline)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return ListTile(
                            title: Text(user['name']?.toString() ?? ''),
                            subtitle: Text('${user['username']} • ${user['role']}'),
                            trailing: Chip(label: Text(user['status']?.toString() ?? '')),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(onPressed: _openAddUserForm, child: const Icon(Icons.add)),
    );
  }
}
