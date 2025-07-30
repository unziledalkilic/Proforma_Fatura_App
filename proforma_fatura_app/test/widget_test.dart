// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proforma_fatura_app/main.dart';

void main() {
  testWidgets('Proforma Fatura App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProformaFaturaApp());

    // Verify that the app starts with splash screen
    expect(find.byType(MaterialApp), findsOneWidget);

    // Wait for splash screen to complete
    await tester.pumpAndSettle();

    // Verify that we can find the main app structure
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
