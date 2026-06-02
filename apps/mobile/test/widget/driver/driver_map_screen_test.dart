import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/features/driver/presentation/screens/driver_map_screen.dart';

// The codegen strips "Notifier" from the class name:
// @riverpod class DriverNotifier → driverProvider (not driverNotifierProvider)
class _FakeNotifier extends DriverNotifier {
  @override
  DriverState build() => const DriverState();
}

void main() {
  testWidgets('shows map placeholder and no preview card by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          openBatchesProvider.overrideWith((_) => const Stream.empty()),
          driverProvider.overrideWith(() => _FakeNotifier()),
        ],
        child: const MaterialApp(home: DriverMapScreen()),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('driver_map')), findsOneWidget);
    expect(find.byKey(const Key('batch_preview_card')), findsNothing);
  });

  testWidgets('shows preview card when selectedBatch is set', (tester) async {
    // Use an explicit ProviderContainer so we can call read() on it outside
    // the widget tree.
    final container = ProviderContainer(
      overrides: [
        openBatchesProvider.overrideWith((_) => const Stream.empty()),
        driverProvider.overrideWith(() => _FakeNotifier()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DriverMapScreen()),
      ),
    );
    await tester.pump();

    const fakeBatch = BatchSummary(
      id: 'b1',
      donorName: 'Central Bakery',
      pickupAddress: '123 Baker St',
      beneficiaryAddress: '456 Shelter Rd',
      beneficiaryName: 'Haven Shelter',
      totalPortions: 38,
      lat: 13.7,
      lng: 100.5,
      foodCategory: 'local_pizza',
    );
    container.read(driverProvider.notifier).selectBatch(fakeBatch);
    await tester.pump();

    expect(find.byKey(const Key('batch_preview_card')), findsOneWidget);
    expect(find.text('Central Bakery'), findsOneWidget);
    expect(find.text('View Job →'), findsOneWidget);
  });
}
