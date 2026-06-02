import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:saveameal/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:saveameal/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:saveameal/shared/theme/app_colors.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeNotificationsRepository implements NotificationsRepository {
  _FakeNotificationsRepository(List<AppNotification> items)
    : _items = List.of(items);
  List<AppNotification> _items;

  @override
  List<AppNotification> getAll() => List.unmodifiable(_items);

  @override
  void markRead(String id) => _items = _items
      .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
      .toList();

  @override
  void markAllRead() =>
      _items = _items.map((n) => n.copyWith(isRead: true)).toList();
}

// ── Seed data ─────────────────────────────────────────────────────────────────

List<AppNotification> _seedNotifications() {
  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));
  return [
    AppNotification(
      id: '1',
      type: NotificationType.deliveryArriving,
      title: 'Driver Arriving Soon',
      body: 'Driver is 5 minutes away.',
      timestamp: now.subtract(const Duration(minutes: 15)),
      isRead: false,
    ),
    AppNotification(
      id: '2',
      type: NotificationType.matchConfirmed,
      title: 'Match Confirmed',
      body: 'Batch assigned.',
      timestamp: now.subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    AppNotification(
      id: '3',
      type: NotificationType.deliverySuccessful,
      title: 'Delivery Successful',
      body: 'Batch delivered today.',
      timestamp: now.subtract(const Duration(hours: 1)),
      isRead: true,
    ),
    AppNotification(
      id: '4',
      type: NotificationType.deliverySuccessful,
      title: 'View Receipt',
      body: 'Goods dropped off.',
      timestamp: yesterday,
      isRead: true,
      actionLabel: 'View Receipt',
      actionBatchId: '8832',
    ),
    AppNotification(
      id: '5',
      type: NotificationType.batchCompleted,
      title: 'Batch Completed',
      body: 'Batch #8411 completed.',
      timestamp: yesterday.subtract(const Duration(hours: 2)),
      isRead: true,
    ),
  ];
}

// ── Test helpers ──────────────────────────────────────────────────────────────

Widget _buildTestApp(List<AppNotification> items) {
  final repo = _FakeNotificationsRepository(items);
  return ProviderScope(
    overrides: [notificationsRepositoryProvider.overrideWith((ref) => repo)],
    child: MaterialApp.router(
      theme: ThemeData(extensions: const [AppColors.light]),
      routerConfig: GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('renders date-grouped sections and unread dots correctly', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp(_seedNotifications()));
    await tester.pump();

    // Section headers
    expect(find.text('TODAY (3)'), findsOneWidget);
    expect(find.text('YESTERDAY (2)'), findsOneWidget);

    // Unread dots visible for isRead: false items
    expect(find.byKey(const ValueKey('unread_dot_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('unread_dot_2')), findsOneWidget);

    // No unread dots for isRead: true items
    expect(find.byKey(const ValueKey('unread_dot_3')), findsNothing);
    expect(find.byKey(const ValueKey('unread_dot_4')), findsNothing);
    expect(find.byKey(const ValueKey('unread_dot_5')), findsNothing);
  });

  testWidgets('Mark all read removes all unread dots', (tester) async {
    await tester.pumpWidget(_buildTestApp(_seedNotifications()));
    await tester.pump();

    // Confirm dots are initially present
    expect(find.byKey(const ValueKey('unread_dot_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('unread_dot_2')), findsOneWidget);

    await tester.tap(find.text('Mark all read'));
    await tester.pump();

    expect(find.byKey(const ValueKey('unread_dot_1')), findsNothing);
    expect(find.byKey(const ValueKey('unread_dot_2')), findsNothing);
  });
}
