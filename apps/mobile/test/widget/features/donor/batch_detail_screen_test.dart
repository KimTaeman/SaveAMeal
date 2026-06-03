import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/batch_item.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/features/donor/presentation/screens/batch_detail_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

Batch _makeBatch({
  String id = 'abc12345',
  BatchStatus status = BatchStatus.open,
  String? driverId,
  String? volunteerName,
  List<BatchItem> items = const [],
  String pickupAddress = '100 Central Hub Road',
}) => Batch(
  id: id,
  donorId: 'donor-uid',
  items: items,
  pickupAddress: pickupAddress,
  status: status,
  driverId: driverId,
  volunteerName: volunteerName,
  createdAt: DateTime(2026, 5, 23, 14, 30),
);

Widget _wrap(Batch batch) {
  final router = GoRouter(
    initialLocation: '/donor/batch/${batch.id}',
    routes: [
      GoRoute(
        path: '/donor',
        builder: (_, _) => const Scaffold(body: Text('Dashboard')),
        routes: [
          GoRoute(
            path: 'batch/:batchId',
            builder: (context, state) =>
                BatchDetailScreen(batchId: state.pathParameters['batchId']!),
            routes: [
              GoRoute(
                path: 'qr',
                builder: (context, state) => Scaffold(
                  body: Text('QR ${state.pathParameters['batchId']}'),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      batchByIdProvider(batch.id).overrideWith((ref) => Stream.value(batch)),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void main() {
  group('BatchDetailScreen', () {
    testWidgets('shows loading indicator while batch loading', (tester) async {
      final router = GoRouter(
        initialLocation: '/donor/batch/abc12345',
        routes: [
          GoRoute(
            path: '/donor/batch/:batchId',
            builder: (context, state) =>
                BatchDetailScreen(batchId: state.pathParameters['batchId']!),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            batchByIdProvider(
              'abc12345',
            ).overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows status-based heading for pickedUp', (tester) async {
      await tester.pumpWidget(_wrap(_makeBatch(status: BatchStatus.pickedUp)));
      await tester.pumpAndSettle();

      expect(find.text('Collected Successfully'), findsOneWidget);
    });

    testWidgets('shows Total Weight and Total Items summary cards', (
      tester,
    ) async {
      final items = [
        BatchItem(
          name: 'Bread',
          category: FoodCategory.bakery,
          weightKg: 2.5,
          expiryTime: DateTime(2026, 6, 10),
        ),
      ];
      await tester.pumpWidget(_wrap(_makeBatch(items: items)));
      await tester.pumpAndSettle();

      expect(find.text('Total Weight'), findsOneWidget);
      expect(find.text('Total Items'), findsOneWidget);
      expect(find.text('2.5 kg'), findsOneWidget);
      expect(find.text('1 Products'), findsOneWidget);
    });

    testWidgets('shows Inventory Breakdown section with item names', (
      tester,
    ) async {
      final items = [
        BatchItem(
          name: 'Sourdough Loaves',
          category: FoodCategory.bakery,
          weightKg: 5.0,
          expiryTime: DateTime(2026, 6, 10),
        ),
        BatchItem(
          name: 'Organic Apples',
          category: FoodCategory.produce,
          weightKg: 8.0,
          expiryTime: DateTime(2026, 6, 10),
        ),
      ];
      await tester.pumpWidget(_wrap(_makeBatch(items: items)));
      await tester.pumpAndSettle();

      expect(find.text('Inventory Breakdown'), findsOneWidget);
      expect(find.text('Sourdough Loaves'), findsOneWidget);
      expect(find.text('Organic Apples'), findsOneWidget);
    });

    testWidgets('hides driver section when volunteerName is null', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_makeBatch(volunteerName: null)));
      await tester.pumpAndSettle();

      expect(find.text('Collected by'), findsNothing);
    });

    testWidgets('shows driver section with volunteer name', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _makeBatch(
            driverId: 'driver-1',
            volunteerName: 'Nattapong',
            status: BatchStatus.pickedUp,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Collected by'), findsOneWidget);
      expect(find.textContaining('Nattapong'), findsOneWidget);
    });

    testWidgets('shows pickup address card', (tester) async {
      await tester.pumpWidget(
        _wrap(_makeBatch(pickupAddress: 'Central Distribution Hub')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Central Distribution Hub'), findsOneWidget);
    });

    testWidgets('QR button visible only on open batch', (tester) async {
      await tester.pumpWidget(_wrap(_makeBatch(status: BatchStatus.open)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.qr_code), findsOneWidget);
    });

    testWidgets('QR button not visible on non-open batch', (tester) async {
      await tester.pumpWidget(_wrap(_makeBatch(status: BatchStatus.delivered)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.qr_code), findsNothing);
    });

    testWidgets('QR button navigates to qr sub-route', (tester) async {
      await tester.pumpWidget(
        _wrap(_makeBatch(id: 'abc12345', status: BatchStatus.open)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.qr_code));
      await tester.pumpAndSettle();

      expect(find.text('QR abc12345'), findsOneWidget);
    });
  });
}
