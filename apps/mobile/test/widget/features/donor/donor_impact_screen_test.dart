import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/features/donor/presentation/screens/donor_impact_screen.dart';
import 'package:saveameal/features/donor/presentation/widgets/donor_bottom_nav.dart';
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

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/donor/impact',
  routes: [
    GoRoute(
      path: '/donor',
      builder: (context, state) =>
          const Scaffold(body: Text('Donor Dashboard')),
      routes: [
        GoRoute(
          path: 'impact',
          builder: (context, state) => const DonorImpactScreen(),
        ),
        GoRoute(
          path: 'batches',
          builder: (context, state) =>
              const Scaffold(body: Text('All Batches Screen')),
        ),
        GoRoute(
          path: 'account',
          builder: (context, state) =>
              const Scaffold(body: Text('Account Screen')),
        ),
      ],
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) =>
          const Scaffold(body: Text('Notifications Screen')),
    ),
  ],
);

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('DonorImpactScreen', () {
    // (1) AppBar title "SaveAMeal" renders
    testWidgets('renders SaveAMeal in AppBar title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(<Batch>[])),
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

    // (2) "TOTAL IMPACT" text renders
    testWidgets('renders TOTAL IMPACT section header', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(<Batch>[])),
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

      expect(find.text('TOTAL IMPACT'), findsOneWidget);
    });

    // (3) "Meals" label renders
    testWidgets('renders Meals label', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(<Batch>[])),
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

      expect(find.text('Meals'), findsOneWidget);
    });

    // (4) DonorBottomNav renders
    testWidgets('renders DonorBottomNav', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(<Batch>[])),
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

      expect(find.byType(DonorBottomNav), findsOneWidget);
    });

    // (5) "By Category" section header renders
    testWidgets('renders By Category section header', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(<Batch>[])),
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

      expect(find.text('By Category'), findsOneWidget);
    });

    // (6) All 6 categories render at 0% when batch list is empty
    testWidgets('shows all categories at 0% when batch list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(<Batch>[])),
            donorMetricsProvider(
              'test-donor-uid',
            ).overrideWith(
              (ref) => Stream.value(
                const DonorMetrics(
                  donorId: 'test-donor-uid',
                  totalKg: 0.0,
                  totalMeals: 0,
                  totalCO2e: 0.0,
                  totalDeliveries: 0,
                ),
              ),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All 6 fixed categories should render
      expect(find.text('Bakery'), findsOneWidget);
      expect(find.text('Produce'), findsOneWidget);
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text('Meat'), findsOneWidget);
      expect(find.text('Beverages'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
      // All show 0%
      expect(find.text('0%'), findsNWidgets(6));
    });

    // (7) Metrics values render from provider
    testWidgets('renders totalMeals value from metrics provider', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeBatchesProvider(
              'test-donor-uid',
            ).overrideWith((ref) => Stream.value(<Batch>[])),
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

      // totalMeals = 2480
      expect(find.text('2480'), findsOneWidget);
    });
  });
}
