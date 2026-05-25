import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/features/driver/presentation/screens/claim_rescue_screen.dart';

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
  _FakeNotifier(this._initial);
  final DriverState _initial;
  @override
  DriverState build() => _initial;
}

void main() {
  testWidgets('en_route_pickup shows donor address and Arrived at Pick-up', (
    tester,
  ) async {
    final notifier = _FakeNotifier(
      const DriverState(
        step: DriverStep.claimed,
        rescuePhase: ClaimRescuePhase.enRoutePickup,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          driverProvider.overrideWith(() => notifier),
          authStateProvider.overrideWith((_) => const Stream.empty()),
          activeBatchForDriverProvider(
            '',
          ).overrideWith((_) => Stream.value(_fakeBatch)),
        ],
        child: const MaterialApp(home: ClaimRescueScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('123 Baker St'), findsOneWidget);
    expect(find.text('Arrived at Pick-up'), findsOneWidget);
    expect(find.text('Arrived at Beneficiary'), findsNothing);
  });

  testWidgets('en_route_beneficiary shows beneficiary address', (tester) async {
    final notifier = _FakeNotifier(
      const DriverState(
        step: DriverStep.pickedUp,
        rescuePhase: ClaimRescuePhase.enRouteBeneficiary,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          driverProvider.overrideWith(() => notifier),
          authStateProvider.overrideWith((_) => const Stream.empty()),
          activeBatchForDriverProvider(
            '',
          ).overrideWith((_) => Stream.value(_fakeBatch)),
        ],
        child: const MaterialApp(home: ClaimRescueScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('1200 Greenway Blvd'), findsOneWidget);
    expect(find.text('Arrived at Beneficiary'), findsOneWidget);
    expect(find.text('Arrived at Pick-up'), findsNothing);
  });
}
