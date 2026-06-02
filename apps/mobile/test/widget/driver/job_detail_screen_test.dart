import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/features/driver/presentation/screens/job_detail_screen.dart';

const _fakeBatch = BatchSummary(
  id: 'b1',
  donorName: 'Central Bakery',
  pickupAddress: '123 Baker St, City Center',
  beneficiaryAddress: '1200 Greenway Blvd',
  beneficiaryName: 'Haven Shelter',
  totalPortions: 38,
  lat: 13.7,
  lng: 100.5,
  foodCategory: 'local_pizza',
  specialInstructions: 'Park at rear',
);

class _NoopNotifier extends DriverNotifier {
  @override
  DriverState build() => const DriverState();
}

void main() {
  testWidgets('renders pickup and dropoff addresses', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [driverProvider.overrideWith(() => _NoopNotifier())],
        child: const MaterialApp(home: JobDetailScreen(batch: _fakeBatch)),
      ),
    );
    expect(find.text('123 Baker St, City Center'), findsOneWidget);
    expect(find.text('1200 Greenway Blvd'), findsOneWidget);
    expect(find.text('Haven Shelter'), findsOneWidget);
    expect(find.text('Park at rear'), findsOneWidget);
    expect(find.text('Accept Job'), findsOneWidget);
  });

  testWidgets('Accept Job button is present and tappable', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [driverProvider.overrideWith(() => _NoopNotifier())],
        child: const MaterialApp(home: JobDetailScreen(batch: _fakeBatch)),
      ),
    );
    expect(find.text('Accept Job'), findsOneWidget);
  });
}
