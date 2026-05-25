import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/presentation/screens/safety_verification_screen.dart';

Widget _wrap() =>
    const ProviderScope(child: MaterialApp(home: SafetyVerificationScreen()));

void main() {
  testWidgets('CTA is disabled when no checkboxes ticked', (tester) async {
    await tester.pumpWidget(_wrap());
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm & Complete Pickup'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('CTA stays disabled after ticking all boxes but no photo', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    final checkboxes = find.byType(CheckboxListTile);
    expect(checkboxes, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      await tester.tap(checkboxes.at(i));
      await tester.pump();
    }
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm & Complete Pickup'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('shows all 3 safety checklist items', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(
      find.text('Food is stored in clean, food-grade containers'),
      findsOneWidget,
    );
    expect(
      find.text('Temperature-sensitive items are in thermal bags'),
      findsOneWidget,
    );
    expect(
      find.text('Vehicle storage area is clean and clear of contaminants'),
      findsOneWidget,
    );
  });
}
