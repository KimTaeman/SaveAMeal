import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/presentation/screens/verify_delivery_screen.dart';

Widget _wrap() =>
    const ProviderScope(child: MaterialApp(home: VerifyDeliveryScreen()));

void main() {
  testWidgets('CTA disabled with nothing checked', (tester) async {
    await tester.pumpWidget(_wrap());
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm Delivery Completion'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('shows both handover verification items', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(
      find.text('Food batch handed over securely to shelter staff'),
      findsOneWidget,
    );
    expect(
      find.text('Shelter staff confirmed item quantities match'),
      findsOneWidget,
    );
  });

  testWidgets('CTA enabled after both checkboxes selected', (tester) async {
    await tester.pumpWidget(_wrap());
    final checks = find.byType(CheckboxListTile);
    await tester.tap(checks.at(0));
    await tester.pump();
    await tester.tap(checks.at(1));
    await tester.pump();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm Delivery Completion'),
    );
    expect(button.onPressed, isNotNull);
  });
}
