import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/delivery_history_notifier.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/delivery_history_screen.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/delivery_history_row.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

const _kBeneficiaryId = 'ben_001';

// Creates [count] fake deliveries.
List<RecentDelivery> _fakeDeliveries(int count) => List.generate(
  count,
  (i) => RecentDelivery(
    batchId: 'abcdefgh${i.toString().padLeft(8, '0')}',
    deliveredAt: DateTime(2024, 1, i + 1),
    portions: 10,
    donorName: 'Donor $i',
    category: 'Hot Meals',
  ),
);

// Fake notifier that immediately returns a fixed state — no Hive/network calls.
class _StubNotifier extends DeliveryHistoryNotifier {
  _StubNotifier(this._fixedState);
  final DeliveryHistoryState _fixedState;

  @override
  Future<DeliveryHistoryState> build(String beneficiaryId) async => _fixedState;

  @override
  Future<void> loadNextPage() async {}

  @override
  Future<void> refresh() async {}
}

// Notifier whose build never completes — simulates loading state.
class _LoadingNotifier extends DeliveryHistoryNotifier {
  final _completer = Completer<DeliveryHistoryState>();

  @override
  Future<DeliveryHistoryState> build(String beneficiaryId) => _completer.future;

  @override
  Future<void> loadNextPage() async {}

  @override
  Future<void> refresh() async {}
}

// Notifier that always throws — simulates initial error state.
class _ErrorNotifier extends DeliveryHistoryNotifier {
  @override
  Future<DeliveryHistoryState> build(String beneficiaryId) async =>
      throw Exception('network error');

  @override
  Future<void> loadNextPage() async {}

  @override
  Future<void> refresh() async {}
}

// Shared GoRouter for tests.
GoRouter _makeRouter() => GoRouter(
  initialLocation: '/history',
  routes: [
    GoRoute(
      path: '/history',
      builder: (context, state) =>
          const DeliveryHistoryScreen(beneficiaryId: _kBeneficiaryId),
    ),
    GoRoute(
      path: '/beneficiary/delivery/:batchId',
      builder: (context, state) =>
          Scaffold(body: Text('detail:${state.pathParameters['batchId']}')),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const Scaffold(body: Text('notifications')),
    ),
  ],
);

void main() {
  testWidgets('shows CircularProgressIndicator on initial loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveryHistoryProvider(
            _kBeneficiaryId,
          ).overrideWith(() => _LoadingNotifier()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _makeRouter(),
        ),
      ),
    );
    await tester.pump(); // first frame — state is AsyncLoading

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(DeliveryHistoryRow), findsNothing);
    expect(find.text('Load More History'), findsNothing);
  });

  testWidgets('renders list rows for populated state', (tester) async {
    final deliveries = _fakeDeliveries(3);
    final populatedState = DeliveryHistoryState(
      items: deliveries,
      hasMore: false,
      isLoadingMore: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveryHistoryProvider(
            _kBeneficiaryId,
          ).overrideWith(() => _StubNotifier(populatedState)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _makeRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DeliveryHistoryRow), findsNWidgets(3));

    // Order ref: first 8 chars of batchId uppercased
    expect(find.text('#ABCDEFGH'), findsWidgets);

    // Donor name
    expect(find.text('From: Donor 0'), findsOneWidget);

    // Chevron icon
    expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));
  });

  testWidgets('shows empty state when no deliveries', (tester) async {
    const emptyState = DeliveryHistoryState(
      items: [],
      hasMore: false,
      isLoadingMore: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveryHistoryProvider(
            _kBeneficiaryId,
          ).overrideWith(() => _StubNotifier(emptyState)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _makeRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your delivery history will appear here'), findsOneWidget);
    expect(find.byType(DeliveryHistoryRow), findsNothing);
    expect(find.text('Load More History'), findsNothing);
  });

  testWidgets('shows error widget with retry button on AsyncError', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveryHistoryProvider(
            _kBeneficiaryId,
          ).overrideWith(() => _ErrorNotifier()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _makeRouter(),
        ),
      ),
    );
    // Allow the error to propagate through the async notifier
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(DeliveryHistoryRow), findsNothing);
  });

  testWidgets('shows "Load More History" button when hasMore is true', (
    tester,
  ) async {
    final state = DeliveryHistoryState(
      items: _fakeDeliveries(3),
      hasMore: true,
      isLoadingMore: false,
      cursor: 'some_cursor',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveryHistoryProvider(
            _kBeneficiaryId,
          ).overrideWith(() => _StubNotifier(state)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _makeRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Load More History', skipOffstage: false), findsOneWidget);
    expect(
      find.text('All deliveries loaded', skipOffstage: false),
      findsNothing,
    );
  });

  testWidgets(
    'hides "Load More" and shows "All deliveries loaded" when hasMore is false',
    (tester) async {
      final state = DeliveryHistoryState(
        items: _fakeDeliveries(3),
        hasMore: false,
        isLoadingMore: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deliveryHistoryProvider(
              _kBeneficiaryId,
            ).overrideWith(() => _StubNotifier(state)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _makeRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('All deliveries loaded', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Load More History', skipOffstage: false), findsNothing);
    },
  );

  testWidgets(
    'shows spinner inside Load More button when isLoadingMore is true',
    (tester) async {
      final state = DeliveryHistoryState(
        items: _fakeDeliveries(3),
        hasMore: true,
        isLoadingMore: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deliveryHistoryProvider(
              _kBeneficiaryId,
            ).overrideWith(() => _StubNotifier(state)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _makeRouter(),
          ),
        ),
      );
      // Use pump() instead of pumpAndSettle() — the CircularProgressIndicator
      // keeps animating and pumpAndSettle would time out.
      await tester.pump();
      await tester.pump();

      // The "Load More History" label is present inside the OutlinedButton.icon.
      expect(
        find.text('Load More History', skipOffstage: false),
        findsOneWidget,
      );
      // Inline spinner is rendered (inside button icon area when isLoadingMore).
      // skipOffstage: false because the footer may be below the visible area.
      expect(
        find.byType(CircularProgressIndicator, skipOffstage: false),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows inline error row when loadMoreError is set', (
    tester,
  ) async {
    final state = DeliveryHistoryState(
      items: _fakeDeliveries(3),
      hasMore: true,
      isLoadingMore: false,
      loadMoreError: Exception('load more failed'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveryHistoryProvider(
            _kBeneficiaryId,
          ).overrideWith(() => _StubNotifier(state)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _makeRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Failed to load more. ', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Retry', skipOffstage: false), findsOneWidget);
    expect(
      find.byIcon(Icons.error_outline, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('stats bar shows disclaimer when hasMore is true', (
    tester,
  ) async {
    final state = DeliveryHistoryState(
      items: _fakeDeliveries(3),
      hasMore: true,
      isLoadingMore: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveryHistoryProvider(
            _kBeneficiaryId,
          ).overrideWith(() => _StubNotifier(state)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _makeRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('*Showing totals for loaded deliveries', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('tapping a row navigates to /beneficiary/delivery/:batchId', (
    tester,
  ) async {
    final deliveries = _fakeDeliveries(1);
    final state = DeliveryHistoryState(
      items: deliveries,
      hasMore: false,
      isLoadingMore: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveryHistoryProvider(
            _kBeneficiaryId,
          ).overrideWith(() => _StubNotifier(state)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _makeRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the DeliveryHistoryRow (which contains an InkWell)
    await tester.tap(find.byType(DeliveryHistoryRow).first);
    await tester.pumpAndSettle();

    // GoRouter should have navigated to the detail page
    expect(find.textContaining('detail:abcdefgh00000000'), findsOneWidget);
  });
}
