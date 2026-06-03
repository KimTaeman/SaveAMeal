import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/features/donor/presentation/screens/donor_dashboard_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

const _testUser = AppUser(
  uid: 'test-donor-uid',
  name: 'FreshMart Supermarket',
  email: 'freshmart@test.com',
  role: UserRole.donor,
);

const _testMetrics = DonorMetrics(
  donorId: 'test-donor-uid',
  totalKg: 1240.0,
  totalMeals: 2480,
  totalCO2e: 372.0,
  totalDeliveries: 42,
);

Batch _makeBatch({
  required String id,
  BatchStatus status = BatchStatus.pickedUp,
}) => Batch(
  id: id,
  donorId: 'test-donor-uid',
  items: const [],
  pickupAddress: '1 Test Road',
  status: status,
  createdAt: DateTime(2026, 5, 23, 14, 30),
);

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/donor',
  routes: [
    GoRoute(
      path: '/donor',
      builder: (context, state) => const DonorDashboardScreen(),
      routes: [
        GoRoute(
          path: 'log',
          builder: (context, state) =>
              const Scaffold(body: Text('Log Batch Screen')),
        ),
        GoRoute(
          path: 'batch/:batchId',
          builder: (context, state) =>
              Scaffold(body: Text('Detail ${state.pathParameters['batchId']}')),
          routes: [
            GoRoute(
              path: 'qr',
              builder: (context, state) =>
                  Scaffold(body: Text('QR ${state.pathParameters['batchId']}')),
            ),
          ],
        ),
        GoRoute(
          path: 'batches',
          builder: (context, state) =>
              const Scaffold(body: Text('All Batches Screen')),
        ),
        GoRoute(
          path: 'impact',
          builder: (context, state) =>
              const Scaffold(body: Text('Impact Screen')),
        ),
        GoRoute(
          path: 'account',
          builder: (context, state) =>
              const Scaffold(body: Text('Account Screen')),
        ),
      ],
    ),
  ],
);

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('DonorDashboardScreen', () {
    // (1) Loading state — auth not yet resolved (stream never emits)
    testWidgets('shows CircularProgressIndicator when auth is not yet resolved', (
      tester,
    ) async {
      // A StreamController that never emits keeps authStateProvider in AsyncLoading.
      final controller = StreamController<AppUser?>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => controller.stream),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );

      // Pump once — no emission yet so the screen shows loading.
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // (2) Loaded state — metrics card displays totalKg
    testWidgets('shows TotalDonatedCard with correct totalKg when loaded', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider('test-donor-uid').overrideWith(
              (ref) => Stream.value([_makeBatch(id: 'abcdef1234567890')]),
            ),
            donorMetricsProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(_testMetrics)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // TOTAL DONATED label is a plain Text widget — always findable.
      expect(find.text('TOTAL DONATED'), findsOneWidget);
      // The kg value is in a RichText with TextSpan — search by widget predicate.
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('1240'),
        ),
        findsWidgets,
      );
    });

    // (2) Loaded state — batch cards rendered
    testWidgets('renders BatchCard for each batch in the list', (tester) async {
      final batches = [
        _makeBatch(id: 'abcdef1234567890'),
        _makeBatch(id: '1234567890abcdef'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(batches)),
            donorMetricsProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(_testMetrics)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Batch #ABCDEF12'), findsOneWidget);
      expect(find.text('Batch #12345678'), findsOneWidget);
    });

    // (3) Empty state — EmptyBatchesCard shown
    testWidgets('shows EmptyBatchesCard when batch list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value([])),
            donorMetricsProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(_testMetrics)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No donations yet'), findsOneWidget);
      expect(find.text('Log your first batch'), findsOneWidget);
    });

    // (5) Log Surplus Batch button navigates to /donor/log
    testWidgets('tapping Log Surplus Batch button navigates to /donor/log', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value([])),
            donorMetricsProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(_testMetrics)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final logButton = find.text('Log Surplus Batch');
      expect(logButton, findsOneWidget);

      await tester.tap(logButton);
      await tester.pumpAndSettle();

      expect(find.text('Log Batch Screen'), findsOneWidget);
    });

    // (6) Tapping a batch card navigates to the batch detail route
    testWidgets('tapping a batch card navigates to /donor/batch/:batchId', (
      tester,
    ) async {
      final batch = _makeBatch(
        id: 'openid1234567890',
        status: BatchStatus.open,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value([batch])),
            donorMetricsProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(_testMetrics)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final card = find.text('Batch #OPENID12');
      expect(card, findsOneWidget);

      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(find.text('Detail openid1234567890'), findsOneWidget);
    });

    // (7) View All link navigates to /donor/batches
    testWidgets('tapping View All navigates to /donor/batches', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value([])),
            donorMetricsProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(_testMetrics)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();

      expect(find.text('All Batches Screen'), findsOneWidget);
    });

    // (8) DonorBottomNav rendered with 4 destinations
    testWidgets('DonorBottomNav renders all 4 destinations', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value([])),
            donorMetricsProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(_testMetrics)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Impact'), findsOneWidget);
      expect(find.text('Batches'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
    });

    // Header renders SaveAMeal logo text
    testWidgets('header renders SaveAMeal text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value([])),
            donorMetricsProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(_testMetrics)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SaveAMeal'), findsOneWidget);
    });

    // Welcome section renders the user name
    testWidgets('welcome section shows the user name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value([])),
            donorMetricsProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(_testMetrics)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.textContaining('Welcome back, FreshMart Supermarket'),
        findsOneWidget,
      );
    });
  });
}
