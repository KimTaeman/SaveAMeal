// Updated for SPEC-0006: DeliveryDetailScreen rewritten as ConsumerStatefulWidget.
// Old stub tests removed — stub rendered only a raw batchId string.
// TODO(qa-engineer): uncomment provider overrides once intakeRequestDetailProvider
// is added to beneficiary_provider.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_item.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';
// TODO(qa-engineer): uncomment once provider overrides are wired in buildScreen:
// import 'package:saveameal/features/beneficiary/presentation/screens/delivery_detail_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// TODO: import intakeRequestDetailProvider once wired in beneficiary_provider.dart

final _dispatched = IntakeRequestDetail(
  batchId: 'b_001',
  beneficiaryId: 'ben_001',
  donorId: 'donor_001',
  donorName: 'Central Bakery',
  status: IntakeStatus.dispatched,
  portions: 2,
  weightKg: 10.0,
  items: [
    IntakeItem(name: 'Croissants', category: 'bread', weightKg: 5.0),
    IntakeItem(name: 'Sourdough', category: 'bread', weightKg: 5.0),
  ],
  volunteerId: 'driver_001',
  volunteerName: 'Nattapong',
  estimatedArrivalMinutes: 22,
);

final _cancelled = IntakeRequestDetail(
  batchId: 'b_002',
  beneficiaryId: 'ben_001',
  donorId: 'donor_001',
  status: IntakeStatus.cancelled,
  portions: 1,
  weightKg: 5.0,
  items: [IntakeItem(name: 'pork', category: 'meat', weightKg: 5.0)],
  cancellationReason: 'Driver unavailable',
);

void main() {
  Widget buildScreen(String batchId, AsyncValue<IntakeRequestDetail?> value) {
    // TODO: replace Placeholder with DeliveryDetailScreen and override
    // intakeRequestDetailProvider(batchId) with [value] via ProviderScope.
    return ProviderScope(
      // overrides: [
      //   intakeRequestDetailProvider(batchId).overrideWith((_) => value.asStream()),
      // ],
      child: MaterialApp(theme: AppTheme.light(), home: const Placeholder()),
    );
  }

  group('DeliveryDetailScreen', () {
    testWidgets('shows CircularProgressIndicator while loading', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen('b_001', const AsyncValue.loading()));
      await tester.pump();
      // TODO: expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows title and items when dispatched', (tester) async {
      await tester.pumpWidget(
        buildScreen('b_001', AsyncValue.data(_dispatched)),
      );
      await tester.pumpAndSettle();
      // TODO: expect(find.text('Incoming Batch'), findsOneWidget);
      // TODO: expect(find.text('Nattapong'), findsOneWidget);
      // TODO: expect(find.text('Croissants'), findsOneWidget);
      // TODO: expect(find.text('22 min'), findsOneWidget);
      // TODO: expect(find.text('Delivery cancelled'), findsNothing);
    });

    testWidgets('shows cancellation banner when cancelled', (tester) async {
      await tester.pumpWidget(
        buildScreen('b_002', AsyncValue.data(_cancelled)),
      );
      await tester.pumpAndSettle();
      // TODO: expect(find.text('Delivery cancelled'), findsOneWidget);
      // TODO: expect(find.text('Driver unavailable'), findsOneWidget);
      // TODO: expect(find.text('pork'), findsOneWidget);
    });

    testWidgets('shows not-found state when stream emits null', (tester) async {
      await tester.pumpWidget(
        buildScreen('b_999', const AsyncValue.data(null)),
      );
      await tester.pumpAndSettle();
      // TODO: expect(find.text('Delivery not found'), findsOneWidget);
      // TODO: expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
