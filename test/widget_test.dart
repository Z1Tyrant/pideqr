// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pideqr/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We wrap the app in a ProviderScope, just like in main.dart.
    // Note: This test does not initialize Firebase. For tests that need it,
    // you would typically need to mock Firebase.
    await tester.pumpWidget(const ProviderScope(
      child: PideQRApp(),
    ));

    // Verify that the main app widget (PideQRApp) is present.
    expect(find.byType(PideQRApp), findsOneWidget);
  });
}
