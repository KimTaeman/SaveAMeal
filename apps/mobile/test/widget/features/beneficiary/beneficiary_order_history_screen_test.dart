import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_profile.dart';
import 'package:saveameal/features/beneficiary/domain/entities/order_history_entry.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_account_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/beneficiary_order_history_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Fixtures ───────────────────────────────────────────────────────────────────

const _testUser = AppUser(
  uid: 'test-uid',
  name: 'Haven Shelter',
  email: 'shelter@example.com',
  role: UserRole.beneficiary,
);

final _testProfile = BeneficiaryProfile(
  uid: 'test-uid',
  name: 'Haven Shelter',
  email: 'shelter@example.com',
  role: 'beneficiary',
  mealsReceived: 450,
  joinedAt: DateTime(2023, 3, 1),
  orgName: 'Haven Shelter',
  orgType: 'Shelter',
);

final _testOrders = [
  OrderHistoryEntry(
    id: 'abc4092',
    date: DateTime(2023, 10, 24),
    status: OrderHistoryEntryStatus.delivered,
    itemDescription: '50 Hot Meals',
    donorName: 'Green Leaf Kitchen',
    totalWeightKg: 20.0,
    foodCategory: 'hot_meals',
  ),
  OrderHistoryEntry(
    id: 'xyz4105',
    date: DateTime(2023, 10, 26),
    status: OrderHistoryEntryStatus.inTransit,
    itemDescription: '120 Baked Goods',
    donorName: 'Sunrise Bakery',
    totalWeightKg: 30.0,
    foodCategory: 'baked_goods',
  ),
];

// ── Router ─────────────────────────────────────────────────────────────────────

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/beneficiary/account/orders',
  routes: [
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const Scaffold(body: Text('Notifications')),
    ),
    GoRoute(
      path: '/beneficiary',
      builder: (context, state) =>
          const Scaffold(body: Text('Beneficiary Home')),
      routes: [
        GoRoute(
          path: 'account',
          builder: (context, state) =>
              const Scaffold(body: Text('Account Screen')),
          routes: [
            GoRoute(
              path: 'orders',
              builder: (context, state) =>
                  const BeneficiaryOrderHistoryScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

// ── Helpers ────────────────────────────────────────────────────────────────────

Widget _buildApp(OrderHistoryState orderState) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
    currentBeneficiaryProfileProvider.overrideWith(
      (ref) => Stream.value(_testProfile),
    ),
    orderHistoryProvider('test-uid').overrideWithValue(orderState),
  ],
  child: MaterialApp.router(
    theme: AppTheme.light(),
    routerConfig: _buildRouter(),
  ),
);

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('BeneficiaryOrderHistoryScreen', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        _buildApp(OrderHistoryState(entries: _testOrders, hasMore: false)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows empty state when no orders', (tester) async {
      await tester.pumpWidget(
        _buildApp(const OrderHistoryState(entries: [], hasMore: false)),
      );
      await tester.pumpAndSettle();
      expect(find.text('No deliveries yet'), findsOneWidget);
    });

    testWidgets('shows order cards for both entries', (tester) async {
      await tester.pumpWidget(
        _buildApp(OrderHistoryState(entries: _testOrders, hasMore: false)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Order #ABC4092'), findsOneWidget);
      expect(find.text('Order #XYZ4105'), findsOneWidget);
    });

    testWidgets('shows Delivered badge for delivered entry', (tester) async {
      await tester.pumpWidget(
        _buildApp(OrderHistoryState(entries: _testOrders, hasMore: false)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Delivered'), findsOneWidget);
    });

    testWidgets('shows In Transit badge for in-transit entry', (tester) async {
      await tester.pumpWidget(
        _buildApp(OrderHistoryState(entries: _testOrders, hasMore: false)),
      );
      await tester.pumpAndSettle();
      expect(find.text('In Transit'), findsOneWidget);
    });

    testWidgets('shows Load More History button when hasMore is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(OrderHistoryState(entries: _testOrders, hasMore: true)),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Load More History'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Load More History'), findsOneWidget);
    });

    testWidgets('Load More History is absent when hasMore is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(OrderHistoryState(entries: _testOrders, hasMore: false)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Load More History'), findsNothing);
    });

    testWidgets('shows delivery count of 2 in stats row', (tester) async {
      await tester.pumpWidget(
        _buildApp(OrderHistoryState(entries: _testOrders, hasMore: false)),
      );
      await tester.pumpAndSettle();
      // deliveryCount = entries.length = 2
      expect(find.text('2'), findsOneWidget);
    });
  });
}
