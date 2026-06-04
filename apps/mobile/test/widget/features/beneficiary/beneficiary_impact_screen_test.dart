import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_impact_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/beneficiary_impact_screen.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/impact_hero_card.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/impact_metric_tile.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Fixtures ───────────────────────────────────────────────────────────────────

const _testUser = AppUser(
  uid: 'test-ben-uid',
  name: 'Hope Centre',
  email: 'hope@test.com',
  role: UserRole.beneficiary,
);

const _loadedImpact = BeneficiaryImpact(
  totalMeals: 4200,
  totalKg: 1680.0,
  totalCo2e: 1680.0,
  totalDeliveries: 21,
  byCategory: {
    FoodCategory.bakery: 500.0,
    FoodCategory.produce: 1000.0,
    FoodCategory.dairy: 0.0,
  },
);

// ── Router ─────────────────────────────────────────────────────────────────────

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/beneficiary/impact',
  routes: [
    GoRoute(
      path: '/beneficiary',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Home'))),
      routes: [
        GoRoute(
          path: 'impact',
          builder: (context, state) => const BeneficiaryImpactScreen(),
        ),
      ],
    ),
  ],
);

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('BeneficiaryImpactScreen', () {
    // 1. Loading state — auth stream has not emitted yet
    testWidgets(
      'shows CircularProgressIndicator when auth stream has not emitted',
      (tester) async {
        final authController = StreamController<AppUser?>();
        addTearDown(authController.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => authController.stream),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: _buildRouter(),
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    // 2. Loading state — impact stream not yet resolved
    testWidgets(
      'shows CircularProgressIndicator while impact stream is loading',
      (tester) async {
        final impactController = StreamController<BeneficiaryImpact>();
        addTearDown(impactController.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
              activeDeliveriesProvider(
                'test-ben-uid',
              ).overrideWith((ref) => Stream.value(const <IntakeRequest>[])),
              beneficiaryImpactProvider(
                'test-ben-uid',
              ).overrideWith((ref) => impactController.stream),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: _buildRouter(),
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    // 3. Loaded state — ImpactHeroCard present, meal count displayed
    testWidgets('shows ImpactHeroCard with meal count when loaded', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            beneficiaryImpactProvider(
              'test-ben-uid',
            ).overrideWith((ref) => Stream.value(_loadedImpact)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ImpactHeroCard), findsOneWidget);
      // The meal count is rendered inside a RichText — check via toPlainText()
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasMealCount = richTexts.any(
        (rt) => rt.text.toPlainText().contains('4200'),
      );
      expect(hasMealCount, isTrue);
    });

    // 4. Loaded state — two ImpactMetricTile widgets rendered
    testWidgets('renders two ImpactMetricTile widgets when loaded', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            beneficiaryImpactProvider(
              'test-ben-uid',
            ).overrideWith((ref) => Stream.value(_loadedImpact)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ImpactMetricTile), findsNWidgets(2));
      expect(find.text('CO2 Diverted'), findsOneWidget);
      expect(find.text('Waste Saved'), findsOneWidget);
    });

    // 5. Loaded state — category rows shown only for non-zero categories
    testWidgets('shows category rows only for categories with kg > 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            beneficiaryImpactProvider(
              'test-ben-uid',
            ).overrideWith((ref) => Stream.value(_loadedImpact)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // bakery (500) and produce (1000) are non-zero; dairy (0) must not render
      expect(find.text('Bakery'), findsOneWidget);
      expect(find.text('Fruits & Veggies'), findsOneWidget);
      expect(find.text('Dairy'), findsNothing);
    });

    // 6. Zero state — "0 Meals" and "Start your journey" shown
    testWidgets('shows zero-state copy when impact is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            beneficiaryImpactProvider(
              'test-ben-uid',
            ).overrideWith((ref) => Stream.value(BeneficiaryImpact.empty)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // RichText contains "0 Meals" — check via ImpactHeroCard being present
      expect(find.byType(ImpactHeroCard), findsOneWidget);
      // The zero-state caption is a plain Text widget
      expect(find.text('Start your journey'), findsOneWidget);
    });

    // 7. Zero state — By Category section is hidden
    testWidgets('hides By Category list in zero state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            beneficiaryImpactProvider(
              'test-ben-uid',
            ).overrideWith((ref) => Stream.value(BeneficiaryImpact.empty)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bakery'), findsNothing);
      expect(find.text('Produce'), findsNothing);
    });

    // 8. Error state — offline banner shown with correct copy
    testWidgets(
      'shows offline banner when beneficiaryImpactProvider emits an error',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
              activeDeliveriesProvider(
                'test-ben-uid',
              ).overrideWith((ref) => Stream.value(const <IntakeRequest>[])),
              beneficiaryImpactProvider(
                'test-ben-uid',
              ).overrideWith((ref) => Stream.error(Exception('network error'))),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: _buildRouter(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Could not load impact data. Check your connection.'),
          findsOneWidget,
        );
      },
    );

    // 9. Error state — fallback renders BeneficiaryImpact.empty layout
    testWidgets(
      'renders zero-state layout with .empty copy when provider errors',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
              activeDeliveriesProvider(
                'test-ben-uid',
              ).overrideWith((ref) => Stream.value(const <IntakeRequest>[])),
              beneficiaryImpactProvider(
                'test-ben-uid',
              ).overrideWith((ref) => Stream.error(Exception('network error'))),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: _buildRouter(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Start your journey'), findsOneWidget);
      },
    );

    // 10. Bottom nav selectedIndex is 2
    testWidgets('NavigationBar has selectedIndex 2 (Impact tab)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            beneficiaryImpactProvider(
              'test-ben-uid',
            ).overrideWith((ref) => Stream.value(BeneficiaryImpact.empty)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 2);
    });

    // 11. AppBar shows SaveAMeal
    testWidgets('shows SaveAMeal in AppBar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            beneficiaryImpactProvider(
              'test-ben-uid',
            ).overrideWith((ref) => Stream.value(BeneficiaryImpact.empty)),
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
  });
}
