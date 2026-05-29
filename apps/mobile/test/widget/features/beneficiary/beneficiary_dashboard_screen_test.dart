import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Test fixtures ──────────────────────────────────────────────────────────────

const _testUser = AppUser(
  uid: 'test-ben-uid',
  name: 'Hope Centre',
  email: 'hope@test.com',
  role: UserRole.beneficiary,
);

IntakeRequest _makeRequest({
  String batchId = 'batch-001',
  IntakeStatus status = IntakeStatus.dispatched,
}) => IntakeRequest(
  batchId: batchId,
  beneficiaryId: 'test-ben-uid',
  donorId: 'donor-001',
  status: status,
  portions: 5,
  mealDescription: 'Pad Thai',
  weightKg: 3.0,
);

// ── Router ─────────────────────────────────────────────────────────────────────

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/beneficiary',
  routes: [
    GoRoute(
      path: '/beneficiary',
      builder: (context, state) => const BeneficiaryHomeScreen(),
      routes: [
        GoRoute(
          path: 'delivery/:batchId',
          builder: (context, state) =>
              Scaffold(body: Text('Detail ${state.pathParameters['batchId']}')),
        ),
      ],
    ),
  ],
);

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('BeneficiaryHomeScreen', () {
    // 1. Loading — auth stream never emits
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

    // 2. Loading — auth returns null (uid empty)
    testWidgets('shows CircularProgressIndicator when auth returns null user', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            intakeAvailabilityProvider('').overrideWith(
              (ref) => Stream.value(BeneficiaryIntakeAvailability.accepting),
            ),
            activeDeliveriesProvider(
              '',
            ).overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // 3. Toggle shows Accepting label when availability is accepting
    testWidgets('shows Accepting toggle label when availability is accepting', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            intakeAvailabilityProvider('test-ben-uid').overrideWith(
              (ref) => Stream.value(BeneficiaryIntakeAvailability.accepting),
            ),
            activeDeliveriesProvider(
              'test-ben-uid',
            ).overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accepting'), findsOneWidget);
    });

    // 4. Toggle shows Full / Busy label when availability is fullBusy
    testWidgets(
      'shows Full / Busy toggle label when availability is fullBusy',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
              intakeAvailabilityProvider('test-ben-uid').overrideWith(
                (ref) => Stream.value(BeneficiaryIntakeAvailability.fullBusy),
              ),
              activeDeliveriesProvider(
                'test-ben-uid',
              ).overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: _buildRouter(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Full / Busy'), findsOneWidget);
      },
    );

    // 5. Empty deliveries state
    testWidgets('shows No active deliveries when delivery list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            intakeAvailabilityProvider('test-ben-uid').overrideWith(
              (ref) => Stream.value(BeneficiaryIntakeAvailability.accepting),
            ),
            activeDeliveriesProvider(
              'test-ben-uid',
            ).overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active deliveries'), findsOneWidget);
    });

    // 6. One ActiveDeliveryCard per delivery
    testWidgets('renders one ActiveDeliveryCard per delivery in the list', (
      tester,
    ) async {
      final deliveries = [
        _makeRequest(batchId: 'batch-A'),
        _makeRequest(batchId: 'batch-B'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            intakeAvailabilityProvider('test-ben-uid').overrideWith(
              (ref) => Stream.value(BeneficiaryIntakeAvailability.accepting),
            ),
            activeDeliveriesProvider(
              'test-ben-uid',
            ).overrideWith((ref) => Stream.value(deliveries)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both dispatched cards show IN TRANSIT badge
      expect(find.text('IN TRANSIT'), findsNWidgets(2));
    });

    // 7. VisibilityInactiveCard (intakePaused) shown when fullBusy
    testWidgets('shows VisibilityInactiveCard Intake Paused when fullBusy', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            intakeAvailabilityProvider('test-ben-uid').overrideWith(
              (ref) => Stream.value(BeneficiaryIntakeAvailability.fullBusy),
            ),
            activeDeliveriesProvider(
              'test-ben-uid',
            ).overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Intake Paused'), findsOneWidget);
    });

    // 8. VisibilityInactiveCard NOT shown when accepting
    testWidgets('does not show VisibilityInactiveCard when accepting', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            intakeAvailabilityProvider('test-ben-uid').overrideWith(
              (ref) => Stream.value(BeneficiaryIntakeAvailability.accepting),
            ),
            activeDeliveriesProvider(
              'test-ben-uid',
            ).overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Intake Paused'), findsNothing);
      expect(find.text('Visibility Inactive'), findsNothing);
    });

    // 9. NavigationBar with 4 destinations
    testWidgets('shows NavigationBar with Home, Track, Impact, Account', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            intakeAvailabilityProvider('test-ben-uid').overrideWith(
              (ref) => Stream.value(BeneficiaryIntakeAvailability.accepting),
            ),
            activeDeliveriesProvider(
              'test-ben-uid',
            ).overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Track'), findsOneWidget);
      expect(find.text('Impact'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
    });

    // 10. AppBar shows SaveAMeal
    testWidgets('shows SaveAMeal in AppBar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            intakeAvailabilityProvider('test-ben-uid').overrideWith(
              (ref) => Stream.value(BeneficiaryIntakeAvailability.accepting),
            ),
            activeDeliveriesProvider(
              'test-ben-uid',
            ).overrideWith((ref) => Stream.value([])),
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

    // 11. Offline banner shown when intakeAvailabilityProvider emits an error
    testWidgets(
      'shows offline banner when intakeAvailabilityProvider emits an error',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
              intakeAvailabilityProvider(
                'test-ben-uid',
              ).overrideWith((ref) => Stream.error(Exception('network'))),
              activeDeliveriesProvider(
                'test-ben-uid',
              ).overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: _buildRouter(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Could not load data. Check your connection.'),
          findsOneWidget,
        );
      },
    );
  });
}
