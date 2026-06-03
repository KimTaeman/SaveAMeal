import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_item.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';
import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/delivery_detail_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

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

/// Builds the screen with provider overrides to avoid real Firestore/Maps calls.
///
/// - [detailStream]: stream returned by intakeRequestDetailProvider
/// - [beneficiaryId]: used to scope the recentDeliveriesProvider override (empty list)
/// - [driverId]: when set, overrides driverLocationProvider(driverId) with null
///   so DriverInfoCard skips GoogleMap and renders the placeholder instead
Widget _buildScreen(
  String batchId,
  Stream<IntakeRequestDetail?> detailStream, {
  String beneficiaryId = 'ben_001',
  String? driverId,
}) {
  return ProviderScope(
    overrides: [
      intakeRequestDetailProvider(batchId).overrideWith((_) => detailStream),
      recentDeliveriesProvider(
        beneficiaryId,
      ).overrideWith((_) => Stream.value(<RecentDelivery>[])),
      if (driverId != null)
        driverLocationProvider(
          driverId,
        ).overrideWith((_) => Stream.value(null)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: DeliveryDetailScreen(batchId: batchId),
    ),
  );
}

void main() {
  group('DeliveryDetailScreen', () {
    testWidgets('shows CircularProgressIndicator while loading', (
      tester,
    ) async {
      final controller = StreamController<IntakeRequestDetail?>();
      addTearDown(controller.close);

      await tester.pumpWidget(_buildScreen('b_001', controller.stream));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows title, driver name, items, and ETA when dispatched', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(
          'b_001',
          Stream.value(_dispatched),
          driverId: 'driver_001',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Incoming Batch'), findsOneWidget);
      expect(find.text('Nattapong'), findsOneWidget);
      expect(find.text('Croissants'), findsOneWidget);
      expect(find.text('22 min'), findsOneWidget);
      expect(find.text('Delivery cancelled'), findsNothing);
    });

    testWidgets('shows cancellation banner and item when cancelled', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen('b_002', Stream.value(_cancelled)));
      await tester.pumpAndSettle();

      expect(find.text('Delivery cancelled'), findsOneWidget);
      expect(find.text('Driver unavailable'), findsOneWidget);
      expect(find.text('pork'), findsOneWidget);
    });

    testWidgets('shows not-found state when stream emits null', (tester) async {
      await tester.pumpWidget(_buildScreen('b_999', Stream.value(null)));
      await tester.pumpAndSettle();

      expect(find.text('Delivery not found'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
