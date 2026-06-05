import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/notifications/data/notification_prefs_store.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:saveameal/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:saveameal/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:saveameal/shared/theme/app_colors.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _InMemoryReadStore implements NotificationReadStore {
  Set<String> _ids = {};

  @override
  Set<String> loadReadIds() => Set.unmodifiable(_ids);

  @override
  void saveReadIds(Set<String> ids) => _ids = Set.from(ids);
}

class _FakeNotificationsRepository implements NotificationsRepository {
  @override
  Stream<List<AppNotification>> watchAll(String uid) => Stream.value([]);

  @override
  Future<void> markRead(String uid, String id) async {}

  @override
  Future<void> markAllRead(String uid) async {}
}

const _fakeUser = AppUser(
  uid: 'test-uid',
  name: 'Test User',
  email: 'test@test.com',
  role: UserRole.driver,
);

// ── Seed data ─────────────────────────────────────────────────────────────────

List<AppNotification> _seedNotifications() {
  final now = DateTime.now();
  final yesterdayNoon = DateTime(now.year, now.month, now.day - 1, 12);
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
      timestamp: yesterdayNoon,
      isRead: true,
      actionLabel: 'View Receipt',
      actionBatchId: '8832',
    ),
    AppNotification(
      id: '5',
      type: NotificationType.batchCompleted,
      title: 'Batch Completed',
      body: 'Batch #8411 completed.',
      timestamp: yesterdayNoon.add(const Duration(hours: 1)),
      isRead: true,
    ),
  ];
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildTestApp(List<AppNotification> items) {
  return ProviderScope(
    overrides: [
      // Provide the stream directly — bypasses Firestore entirely.
      notificationsStreamProvider.overrideWith((ref) => Stream.value(items)),
      // Also override the repository so markRead/markAllRead don't hit Firestore.
      notificationsRepositoryProvider.overrideWith(
        (_) => _FakeNotificationsRepository(),
      ),
      authStateProvider.overrideWith((_) => Stream.value(_fakeUser)),
      notificationReadStoreProvider.overrideWith((_) => _InMemoryReadStore()),
    ],
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
    await tester.pumpAndSettle();

    expect(find.text('TODAY (3)'), findsOneWidget);
    expect(find.text('YESTERDAY (2)'), findsOneWidget);

    expect(find.byKey(const ValueKey('unread_dot_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('unread_dot_2')), findsOneWidget);

    expect(find.byKey(const ValueKey('unread_dot_3')), findsNothing);
    expect(find.byKey(const ValueKey('unread_dot_4')), findsNothing);
    expect(find.byKey(const ValueKey('unread_dot_5')), findsNothing);
  });

  testWidgets('Mark all read removes all unread dots', (tester) async {
    await tester.pumpWidget(_buildTestApp(_seedNotifications()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('unread_dot_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('unread_dot_2')), findsOneWidget);

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('unread_dot_1')), findsNothing);
    expect(find.byKey(const ValueKey('unread_dot_2')), findsNothing);
  });
}
