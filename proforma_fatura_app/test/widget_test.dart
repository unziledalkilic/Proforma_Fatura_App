import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proforma_fatura_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the register screen is loaded
    expect(find.text('Proforma Fatura'), findsOneWidget);
  });
}

// flutter run
