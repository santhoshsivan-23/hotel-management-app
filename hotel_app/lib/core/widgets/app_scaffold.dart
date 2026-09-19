import 'package:flutter/material.dart';
import 'sidebar_nav.dart';
import 'sync_status_badge.dart';

/// Shared Scaffold every top-level (sidebar-reachable) screen uses, so the
/// app bar, drawer, and sync badge stay consistent everywhere instead of
/// being re-declared per screen.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentRoute,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final String currentRoute;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: SyncStatusBadge()),
          ),
          ...?actions,
        ],
      ),
      drawer: SidebarNav(currentRoute: currentRoute),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
