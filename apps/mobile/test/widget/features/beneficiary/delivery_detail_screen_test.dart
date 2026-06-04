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
import 'package:go_router/go_router.dart';

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

final _delivered = IntakeRequestDetail(
  batchId: 'b_001',
  beneficiaryId: 'ben_001',
  donorId: 'donor_001',
  donorName: 'Central Bakery',
  status: IntakeStatus.delivered,
  portions: 2,
  weightKg: 10.0,
  items: [IntakeItem(name: 'Croissants', category: 'bread', weightKg: 5.0)],
);

final _closed = IntakeRequestDetail(
  batchId: 'b_001',
  beneficiaryId: 'ben_001',
  donorId: 'donor_001',
  donorName: 'Central Bakery',
  status: IntakeStatus.closed,
  portions: 2,
  weightKg: 10.0,
  items: [IntakeItem(name: 'Croissants', category: 'bread', weightKg: 5.0)],
);

final _open = IntakeRequestDetail(
  batchId: 'b_001',
  beneficiaryId: 'ben_001',
  donorId: 'donor_001',
  status: IntakeStatus.open,
  portions: 1,
  weightKg: 5.0,
  items: [IntakeItem(name: 'Rice', category: 'grain', weightKg: 5.0)],
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

    // ── Confirm Receipt feature tests ─────────────────────────────────────

    // (1) "Confirm Receipt" button is visible when status == delivered
    testWidgets(
      '"Confirm Receipt" button is visible when status == delivered',
      (tester) async {
        await tester.pumpWidget(
          _buildScreen('b_001', Stream.value(_delivered)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Confirm Receipt'), findsOneWidget);
      },
    );

    // (2) button is absent when status == open
    testWidgets('"Confirm Receipt" button is absent when status == open', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen('b_001', Stream.value(_open)));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Receipt'), findsNothing);
    });

    // (3) button is absent when status == dispatched
    testWidgets(
      '"Confirm Receipt" button is absent when status == dispatched',
      (tester) async {
        await tester.pumpWidget(
          _buildScreen(
            'b_001',
            Stream.value(_dispatched),
            driverId: 'driver_001',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Confirm Receipt'), findsNothing);
      },
    );

    // (4) button is absent when status == cancelled
    testWidgets('"Confirm Receipt" button is absent when status == cancelled', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen('b_002', Stream.value(_cancelled)));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Receipt'), findsNothing);
    });

    // (5) button is absent when status == closed
    testWidgets('"Confirm Receipt" button is absent when status == closed', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen('b_001', Stream.value(_closed)));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Receipt'), findsNothing);
    });

    // (6) tapping the button navigates to the confirm route
    testWidgets('tapping "Confirm Receipt" pushes to the confirm route', (
      tester,
    ) async {
      String? pushedRoute;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/beneficiary/delivery/:batchId',
            builder: (_, state) =>
                _buildScreen('b_001', Stream.value(_delivered)),
            routes: [
              GoRoute(
                path: 'confirm',
                builder: (context, state) =>
                    const Scaffold(body: Text('Confirm screen')),
              ),
            ],
          ),
        ],
        observers: [_RouteObserver(onPush: (r) => pushedRoute = r)],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            intakeRequestDetailProvider(
              'b_001',
            ).overrideWith((_) => Stream.value(_delivered)),
            recentDeliveriesProvider(
              'ben_001',
            ).overrideWith((_) => Stream.value(<RecentDelivery>[])),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );

      router.go('/beneficiary/delivery/b_001');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm Receipt'));
      await tester.pumpAndSettle();

      expect(pushedRoute, contains('confirm'));
    });

    // (7) _ConfirmationBanner is shown when status == closed
    testWidgets(
      '_ConfirmationBanner "Receipt confirmed" is shown when status == closed',
      (tester) async {
        await tester.pumpWidget(_buildScreen('b_001', Stream.value(_closed)));
        await tester.pumpAndSettle();

        expect(find.text('Receipt confirmed'), findsOneWidget);
      },
    );

    // (8) _ConfirmationBanner is absent when status != closed
    testWidgets('_ConfirmationBanner is absent when status != closed', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen('b_001', Stream.value(_delivered)));
      await tester.pumpAndSettle();

      expect(find.text('Receipt confirmed'), findsNothing);
    });
  });
}

class _RouteObserver extends NavigatorObserver {
  _RouteObserver({required this.onPush});
  final void Function(String route) onPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) onPush(name);
  }
}
