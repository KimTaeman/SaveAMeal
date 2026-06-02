import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/features/driver/presentation/screens/pickup_verification_screen.dart';

const _fakeBatch = BatchSummary(
  id: 'b1',
  donorName: 'Central Bakery',
  pickupAddress: '123 Baker St',
  beneficiaryAddress: '1200 Greenway Blvd',
  beneficiaryName: 'Haven Shelter',
  totalPortions: 38,
  lat: 13.7,
  lng: 100.5,
  foodCategory: 'local_pizza',
);

class _FakeNotifier extends DriverNotifier {
  @override
  DriverState build() => DriverState(
    step: DriverStep.claimed,
    rescuePhase: ClaimRescuePhase.enRoutePickup,
    activeBatch: _fakeBatch,
  );
}

class _FakeEmptyNotifier extends DriverNotifier {
  @override
  DriverState build() => const DriverState();
}

Widget _wrapWithBatch() => ProviderScope(
  overrides: [driverProvider.overrideWith(() => _FakeNotifier())],
  child: const MaterialApp(home: PickupVerificationScreen()),
);

Widget _wrap() => ProviderScope(
  overrides: [driverProvider.overrideWith(() => _FakeEmptyNotifier())],
  child: const MaterialApp(home: PickupVerificationScreen()),
);

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

  testWidgets(
    'donor info card shows donor name and portions when batch active',
    (tester) async {
      await tester.pumpWidget(_wrapWithBatch());
      await tester.pump();
      expect(find.text('Central Bakery'), findsOneWidget);
      expect(find.text('38 portions'), findsOneWidget);
    },
  );

  testWidgets('manual entry Confirm is disabled when text is empty', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Problems scanning? Enter code manually'));
    await tester.pumpAndSettle();
    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm'),
    );
    expect(confirm.onPressed, isNull);
  });
}
