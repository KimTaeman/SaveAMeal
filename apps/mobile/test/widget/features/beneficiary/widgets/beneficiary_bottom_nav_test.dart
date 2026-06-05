import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/beneficiary_bottom_nav.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Fixtures ───────────────────────────────────────────────────────────────────

const _testUser = AppUser(
  uid: 'test-uid',
  name: 'Haven Shelter',
  email: 'shelter@example.com',
  role: UserRole.beneficiary,
);

final _testDelivery = IntakeRequest(
  batchId: 'delivery-1',
  beneficiaryId: 'test-uid',
  donorId: 'donor-1',
  status: IntakeStatus.dispatched,
  portions: 4,
  mealDescription: 'Hot Meals',
  weightKg: 5.0,
);

// ── Helper ─────────────────────────────────────────────────────────────────────

Widget _buildApp({
  required AppUser? user,
  required List<IntakeRequest> deliveries,
  int currentIndex = 0,
  void Function(int)? onDestinationSelected,
}) {
  final uid = user?.uid ?? '';
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(user)),
      activeDeliveriesProvider(
        uid,
      ).overrideWith((ref) => Stream.value(deliveries)),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (ctx, state) => Scaffold(
              body: const Center(child: Text('Home Screen')),
              bottomNavigationBar: BeneficiaryBottomNav(
                currentIndex: currentIndex,
                onDestinationSelected: onDestinationSelected,
              ),
            ),
          ),
          GoRoute(
            path: '/beneficiary',
            builder: (ctx, state) =>
                const Scaffold(body: Text('Beneficiary Home')),
          ),
          GoRoute(
            path: '/beneficiary/delivery/:id',
            builder: (ctx, state) =>
                Scaffold(body: Text('Delivery ${state.pathParameters['id']}')),
          ),
          GoRoute(
            path: '/beneficiary/history',
            builder: (ctx, state) =>
                const Scaffold(body: Text('History Screen')),
          ),
          GoRoute(
            path: '/beneficiary/impact',
            builder: (ctx, state) =>
                const Scaffold(body: Text('Impact Screen')),
          ),
          GoRoute(
            path: '/beneficiary/account',
            builder: (ctx, state) =>
                const Scaffold(body: Text('Account Screen')),
          ),
        ],
      ),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('BeneficiaryBottomNav', () {
    testWidgets(
      'Track tab routes to history when there are no active deliveries',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(user: _testUser, deliveries: const []),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.local_shipping_outlined));
        await tester.pumpAndSettle();

        expect(find.text('History Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'Track tab routes to delivery detail when there is an active delivery',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(user: _testUser, deliveries: [_testDelivery]),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.local_shipping_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Delivery delivery-1'), findsOneWidget);
      },
    );

    testWidgets('Home tab routes to /beneficiary', (tester) async {
      await tester.pumpWidget(
        _buildApp(user: _testUser, deliveries: const [], currentIndex: 1),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Beneficiary Home'), findsOneWidget);
    });

    testWidgets('Impact tab routes to /beneficiary/impact', (tester) async {
      await tester.pumpWidget(_buildApp(user: _testUser, deliveries: const []));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.favorite_outline));
      await tester.pumpAndSettle();

      expect(find.text('Impact Screen'), findsOneWidget);
    });

    testWidgets('Account tab routes to /beneficiary/account', (tester) async {
      await tester.pumpWidget(_buildApp(user: _testUser, deliveries: const []));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      expect(find.text('Account Screen'), findsOneWidget);
    });

    testWidgets(
      'onDestinationSelected override takes precedence over default routing',
      (tester) async {
        int? tappedIndex;
        await tester.pumpWidget(
          _buildApp(
            user: _testUser,
            deliveries: const [],
            onDestinationSelected: (i) => tappedIndex = i,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.local_shipping_outlined));
        await tester.pumpAndSettle();

        // Callback fired with correct index; no navigation occurred.
        expect(tappedIndex, 1);
        expect(find.text('Home Screen'), findsOneWidget);
      },
    );
  });
}
