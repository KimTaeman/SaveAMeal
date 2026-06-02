import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/presentation/screens/pickup_verification_screen.dart';

Widget _wrap() =>
    const ProviderScope(child: MaterialApp(home: PickupVerificationScreen()));

void main() {
  testWidgets('shows Verify Pickup title and scan instructions', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Verify Pickup'), findsOneWidget);
    expect(find.text("Scan the QR code on the donor's device"), findsOneWidget);
    expect(find.text('Problems scanning? Enter code manually'), findsOneWidget);
  });

  testWidgets('tapping manual entry shows dialog', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Problems scanning? Enter code manually'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Enter Batch ID'), findsOneWidget);
  });
}
