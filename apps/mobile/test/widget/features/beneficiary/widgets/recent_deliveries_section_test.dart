import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/recent_deliveries_section.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// Builds RecentDeliveriesSection under a ProviderScope with a stub stream.
Widget _buildSection({
  required String beneficiaryId,
  required AsyncValue<List<RecentDelivery>> value,
}) {
  return ProviderScope(
    overrides: [
      recentDeliveriesProvider(beneficiaryId).overrideWith(
        (_) => value.when(
          data: Stream.value,
          loading: () => const Stream.empty(),
          error: (e, st) => Stream.error(e, st),
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: RecentDeliveriesSection(beneficiaryId: beneficiaryId),
      ),
    ),
  );
}

// Builds with a GoRouter so navigation calls can be verified.
Widget _buildSectionWithRouter({
  required String beneficiaryId,
  required AsyncValue<List<RecentDelivery>> value,
}) {
  final router = GoRouter(
    initialLocation: '/section',
    routes: [
      GoRoute(
        path: '/section',
        builder: (ctx, state) => Scaffold(
          body: RecentDeliveriesSection(beneficiaryId: beneficiaryId),
        ),
      ),
      GoRoute(
        path: '/beneficiary/delivery/:id',
        builder: (ctx, state) =>
            Scaffold(body: Text('Delivery ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/beneficiary/history',
        builder: (ctx, state) => const Scaffold(body: Text('History Screen')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      recentDeliveriesProvider(beneficiaryId).overrideWith(
        (_) => value.when(
          data: Stream.value,
          loading: () => const Stream.empty(),
          error: (e, st) => Stream.error(e, st),
        ),
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

// Reusable deliveries fixture.
final _deliveries = [
  RecentDelivery(
    batchId: 'b_001',
    deliveredAt: DateTime(2026, 6, 3, 18, 45),
    portions: 4,
    donorName: 'Central Bakery',
  ),
  RecentDelivery(
    batchId: 'b_002',
    deliveredAt: DateTime(2026, 6, 2, 19, 20),
    portions: 2,
    donorName: 'Green Farm',
  ),
  RecentDelivery(
    batchId: 'b_003',
    deliveredAt: DateTime(2026, 6, 1, 10, 0),
    portions: 3,
  ),
];

void main() {
  group('RecentDeliveriesSection', () {
    testWidgets('shows header and spinner while loading', (tester) async {
      await tester.pumpWidget(
        _buildSection(
          beneficiaryId: 'ben_001',
          value: const AsyncValue.loading(),
        ),
      );
      await tester.pump();

      // Header stays visible during load; spinner replaces delivery rows.
      expect(find.text('Recent Deliveries'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink on error', (tester) async {
      await tester.pumpWidget(
        _buildSection(
          beneficiaryId: 'ben_001',
          value: AsyncValue.error(Exception('fail'), StackTrace.empty),
        ),
      );
      // pumpAndSettle so the stream error is delivered before asserting.
      await tester.pumpAndSettle();

      expect(find.text('Recent Deliveries'), findsNothing);
    });

    testWidgets('renders SizedBox.shrink when list is empty', (tester) async {
      await tester.pumpWidget(
        _buildSection(
          beneficiaryId: 'ben_001',
          value: const AsyncValue.data([]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent Deliveries'), findsNothing);
    });

    testWidgets('shows section header and View All button with deliveries', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSection(
          beneficiaryId: 'ben_001',
          value: AsyncValue.data(_deliveries),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent Deliveries'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
    });

    testWidgets('renders a row for each delivery', (tester) async {
      await tester.pumpWidget(
        _buildSection(
          beneficiaryId: 'ben_001',
          value: AsyncValue.data(_deliveries),
        ),
      );
      await tester.pumpAndSettle();

      // Three cards rendered.
      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('shows portions and donor name in subtitle', (tester) async {
      await tester.pumpWidget(
        _buildSection(
          beneficiaryId: 'ben_001',
          value: AsyncValue.data([_deliveries.first]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('4 Portions'), findsOneWidget);
      expect(find.textContaining('Central Bakery'), findsOneWidget);
    });

    testWidgets('shows portions without bullet when donorName is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSection(
          beneficiaryId: 'ben_001',
          value: AsyncValue.data([_deliveries[2]]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 Portions'), findsOneWidget);
      expect(find.textContaining('•'), findsNothing);
    });

    testWidgets('green checkmark circle is present for each row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSection(
          beneficiaryId: 'ben_001',
          value: AsyncValue.data(_deliveries),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.check_rounded,
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('chevron right icon is present for each row', (tester) async {
      await tester.pumpWidget(
        _buildSection(
          beneficiaryId: 'ben_001',
          value: AsyncValue.data(_deliveries),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.chevron_right,
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('tapping a delivery card navigates to its detail screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSectionWithRouter(
          beneficiaryId: 'ben_001',
          value: AsyncValue.data([_deliveries.first]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      expect(find.text('Delivery b_001'), findsOneWidget);
    });

    testWidgets('tapping View All navigates to order history screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSectionWithRouter(
          beneficiaryId: 'ben_001',
          value: AsyncValue.data(_deliveries),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();

      expect(find.text('History Screen'), findsOneWidget);
    });
  });

  group('_formatRelativeDate (via rendered text)', () {
    // These tests pump a single-item section and inspect the title text
    // that _formatRelativeDate produces.

    testWidgets('displays Today label for a delivery made today', (
      tester,
    ) async {
      final now = DateTime.now();
      final todayDelivery = RecentDelivery(
        batchId: 'b_today',
        deliveredAt: DateTime(now.year, now.month, now.day, 14, 30),
        portions: 1,
      );

      await tester.pumpWidget(
        _buildSection(
          beneficiaryId: 'ben_001',
          value: AsyncValue.data([todayDelivery]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Today,'), findsOneWidget);
    });

    testWidgets('displays Yesterday label for a delivery made yesterday', (
      tester,
    ) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDelivery = RecentDelivery(
        batchId: 'b_yesterday',
        deliveredAt: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          18,
          45,
        ),
        portions: 1,
      );

      await tester.pumpWidget(
        _buildSection(
          beneficiaryId: 'ben_001',
          value: AsyncValue.data([yesterdayDelivery]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Yesterday,'), findsOneWidget);
    });

    testWidgets('displays N days ago label for deliveries within the week', (
      tester,
    ) async {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final delivery = RecentDelivery(
        batchId: 'b_3d',
        deliveredAt: DateTime(
          threeDaysAgo.year,
          threeDaysAgo.month,
          threeDaysAgo.day,
          10,
          0,
        ),
        portions: 1,
      );

      await tester.pumpWidget(
        _buildSection(
          beneficiaryId: 'ben_001',
          value: AsyncValue.data([delivery]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('3 days ago,'), findsOneWidget);
    });

    testWidgets('displays dd/mm/yyyy for deliveries older than 7 days', (
      tester,
    ) async {
      final old = DateTime(2026, 1, 5, 9, 15);
      final delivery = RecentDelivery(
        batchId: 'b_old',
        deliveredAt: old,
        portions: 1,
      );

      await tester.pumpWidget(
        _buildSection(
          beneficiaryId: 'ben_001',
          value: AsyncValue.data([delivery]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('05/01/2026,'), findsOneWidget);
    });
  });
}
