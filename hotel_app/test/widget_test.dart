// Basic smoke test: the app should build its widget tree without
// throwing. Network and database calls in main() mean the full app isn't
// booted here (that needs platform channels a plain `flutter test` doesn't
// provide); this instead verifies the LoginScreen itself renders, which is
// the most useful pure-widget smoke test that doesn't need a live backend.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hotel_app/core/auth/auth_service.dart';
import 'package:hotel_app/core/network/api_client.dart';
import 'package:hotel_app/features/auth/providers/auth_provider.dart';
import 'package:hotel_app/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen shows username and password fields', (WidgetTester tester) async {
    final apiClient = ApiClient();
    final authService = AuthService(apiClient: apiClient);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(authService),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
