import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/notifications/data/notification_prefs_store.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:saveameal/features/notifications/presentation/providers/notifications_provider.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────────

class _FakeRepository implements NotificationsRepository {
  final List<AppNotification> _items;
  _FakeRepository(this._items);

  @override
  List<AppNotification> getAll() => _items;

  @override
  void markRead(String id) {}

  @override
  void markAllRead() {}
}

class _InMemoryReadStore implements NotificationReadStore {
  Set<String> _ids = {};

  @override
  Set<String> loadReadIds() => Set.unmodifiable(_ids);

  @override
  void saveReadIds(Set<String> ids) => _ids = Set.from(ids);
}

// ── Helpers ────────────────────────────────────────────────────────────────────

const _donor = AppUser(
  uid: 'u1',
  name: 'Khun Siriporn',
  email: 'donor@test.com',
  role: UserRole.donor,
);

AppNotification _notif(
  String id,
  NotificationType type, {
  bool isRead = false,
}) => AppNotification(
  id: id,
  type: type,
  title: 'T',
  body: 'B',
  timestamp: DateTime(2026),
  isRead: isRead,
);

// Returns a container whose auth stream has already emitted, so the
// NotificationsNotifier is guaranteed to have the correct role when read.
Future<ProviderContainer> _container(
  List<AppNotification> notifs, {
  AppUser? user = _donor,
  NotificationReadStore? readStore,
}) async {
  final c = ProviderContainer(
    overrides: [
      authStateProvider.overrideWith((_) => Stream.value(user)),
      notificationsRepositoryProvider.overrideWith(
        (_) => _FakeRepository(notifs),
      ),
      notificationReadStoreProvider.overrideWith(
        (_) => readStore ?? _InMemoryReadStore(),
      ),
    ],
  );
  // Subscribe then drain two microtask turns so Stream.value emits and
  // the dependent NotificationsNotifier rebuilds with the correct role.
  c.listen(authStateProvider, (_, __) {});
  await Future.microtask(() {});
  await Future.microtask(() {});
  return c;
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('NotificationsNotifier — donor role filtering', () {
    test('shows matchConfirmed for donor', () async {
      final c = await _container([
        _notif('1', NotificationType.matchConfirmed),
      ]);
      addTearDown(c.dispose);
      expect(c.read(notificationsProvider).map((n) => n.id), contains('1'));
    });

    test('shows driverAssigned for donor', () async {
      final c = await _container([
        _notif('1', NotificationType.driverAssigned),
      ]);
      addTearDown(c.dispose);
      expect(c.read(notificationsProvider).map((n) => n.id), contains('1'));
    });

    test('shows deliverySuccessful for donor', () async {
      final c = await _container([
        _notif('1', NotificationType.deliverySuccessful),
      ]);
      addTearDown(c.dispose);
      expect(c.read(notificationsProvider).map((n) => n.id), contains('1'));
    });

    test('shows batchCompleted for donor', () async {
      final c = await _container([
        _notif('1', NotificationType.batchCompleted),
      ]);
      addTearDown(c.dispose);
      expect(c.read(notificationsProvider).map((n) => n.id), contains('1'));
    });

    test('hides newBatch for donor', () async {
      final c = await _container([_notif('1', NotificationType.newBatch)]);
      addTearDown(c.dispose);
      expect(c.read(notificationsProvider), isEmpty);
    });

    test('hides deliveryArriving for donor', () async {
      final c = await _container([
        _notif('1', NotificationType.deliveryArriving),
      ]);
      addTearDown(c.dispose);
      expect(c.read(notificationsProvider), isEmpty);
    });

    test(
      'only returns donor-relevant notifications from a mixed list',
      () async {
        final mixed = [
          _notif('keep-1', NotificationType.matchConfirmed),
          _notif('drop-1', NotificationType.newBatch),
          _notif('keep-2', NotificationType.batchCompleted),
          _notif('drop-2', NotificationType.deliveryArriving),
          _notif('keep-3', NotificationType.driverAssigned),
        ];
        final c = await _container(mixed);
        addTearDown(c.dispose);
        final ids = c.read(notificationsProvider).map((n) => n.id).toList();
        expect(ids, containsAll(['keep-1', 'keep-2', 'keep-3']));
        expect(ids, isNot(contains('drop-1')));
        expect(ids, isNot(contains('drop-2')));
      },
    );
  });

  group('NotificationsNotifier — read state persistence', () {
    test('markRead persists across provider rebuild', () async {
      final store = _InMemoryReadStore();
      final notifs = [_notif('1', NotificationType.matchConfirmed)];

      final c1 = await _container(notifs, readStore: store);
      c1.read(notificationsProvider.notifier).markRead('1');
      c1.dispose();

      final c2 = await _container(notifs, readStore: store);
      addTearDown(c2.dispose);
      expect(c2.read(notificationsProvider).first.isRead, isTrue);
    });

    test('markAllRead persists across provider rebuild', () async {
      final store = _InMemoryReadStore();
      final notifs = [
        _notif('1', NotificationType.matchConfirmed),
        _notif('2', NotificationType.batchCompleted),
      ];

      final c1 = await _container(notifs, readStore: store);
      c1.read(notificationsProvider.notifier).markAllRead();
      c1.dispose();

      final c2 = await _container(notifs, readStore: store);
      addTearDown(c2.dispose);
      expect(c2.read(notificationsProvider).every((n) => n.isRead), isTrue);
    });

    test('notification already marked read in mock shows as read', () async {
      final c = await _container([
        _notif('1', NotificationType.batchCompleted, isRead: true),
      ]);
      addTearDown(c.dispose);
      expect(c.read(notificationsProvider).first.isRead, isTrue);
    });

    test(
      'notification in store shows as read even if mock has isRead=false',
      () async {
        final store = _InMemoryReadStore();
        store.saveReadIds({'1'});
        final c = await _container([
          _notif('1', NotificationType.matchConfirmed, isRead: false),
        ], readStore: store);
        addTearDown(c.dispose);
        expect(c.read(notificationsProvider).first.isRead, isTrue);
      },
    );
  });
}
