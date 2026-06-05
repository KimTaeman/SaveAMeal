import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/features/driver/presentation/screens/delivery_completed_screen.dart';
import 'package:saveameal/shared/domain/entities/batch_status.dart';

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
  status: BatchStatus.delivered,
);

class _FakeNotifier extends DriverNotifier {
  @override
  DriverState build() =>
      DriverState(step: DriverStep.delivered, activeBatch: _fakeBatch);
  @override
  void resetToIdle() {}
}

Widget _wrap() => ProviderScope(
  overrides: [driverProvider.overrideWith(() => _FakeNotifier())],
  child: const MaterialApp(home: DeliveryCompletedScreen()),
);

void main() {
  testWidgets('shows Delivery Completed heading', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    expect(find.text('Delivery Completed!'), findsOneWidget);
  });

  testWidgets('shows beneficiary name in summary', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    expect(find.textContaining('Haven Shelter'), findsOneWidget);
  });

  testWidgets('Done and Back to Dashboard buttons present', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Back to Dashboard'), findsOneWidget);
  });
}
