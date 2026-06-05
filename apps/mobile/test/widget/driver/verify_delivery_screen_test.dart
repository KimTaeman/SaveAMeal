import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/features/driver/presentation/screens/verify_delivery_screen.dart';

const _fakeBatch = BatchSummary(
  id: '3f2c1a7b-e5d4-4c8a-9b2f-1234567890ab',
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
  DriverState build() => const DriverState(step: DriverStep.pickedUp);
}

Widget _wrapWithBatch() => ProviderScope(
  overrides: [
    driverProvider.overrideWith(() => _FakeNotifier()),
    authStateProvider.overrideWith((_) => const Stream.empty()),
    activeBatchForDriverProvider(
      '',
    ).overrideWith((_) => Stream.value(_fakeBatch)),
  ],
  child: const MaterialApp(home: VerifyDeliveryScreen()),
);

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

  testWidgets('batch identifier card shows id and portions when batch active', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapWithBatch());
    await tester.pump();
    expect(find.text('Batch #3F2C1A7B'), findsOneWidget);
    expect(find.text('38 Portions'), findsOneWidget);
  });
}
