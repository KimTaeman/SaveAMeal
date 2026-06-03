import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/donor/presentation/providers/notification_preference_provider.dart';
import 'package:saveameal/features/notifications/data/notification_prefs_store.dart';
import 'package:saveameal/services/fcm_service.dart';
import 'package:saveameal/services/firestore_service.dart';
import 'package:saveameal/services/service_providers.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────────

class _FakeFcmService implements FcmService {
  bool permissionRequested = false;
  String? tokenToReturn = 'test-token-abc';
  final List<String> subscribedTopics = [];
  final List<String> unsubscribedTopics = [];

  @override
  Future<void> requestPermission() async => permissionRequested = true;

  @override
  Future<String?> getToken() async => tokenToReturn;

  @override
  Future<void> subscribeToTopic(String topic) async =>
      subscribedTopics.add(topic);

  @override
  Future<void> unsubscribeFromTopic(String topic) async =>
      unsubscribedTopics.add(topic);
}

class _FakeFirestoreService implements FirestoreService {
  String? lastFcmTokenUid;
  String? lastFcmToken;
  Map<String, dynamic>? lastUpdateFields;

  @override
  Future<void> updateFcmToken(String uid, String token) async {
    lastFcmTokenUid = uid;
    lastFcmToken = token;
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    lastFcmTokenUid = uid;
    lastUpdateFields = fields;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

class _FakePrefStore implements NotificationPrefStore {
  bool _stored;
  _FakePrefStore({bool initial = false}) : _stored = initial;

  @override
  bool load() => _stored;

  @override
  Future<void> save(bool value) async => _stored = value;
}

// ── Helper ─────────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer({
  required _FakeFcmService fcm,
  required _FakeFirestoreService firestore,
  required _FakePrefStore store,
}) => ProviderContainer(
  overrides: [
    fcmServiceProvider.overrideWithValue(fcm),
    firestoreServiceProvider.overrideWithValue(firestore),
    notificationPrefStoreProvider.overrideWithValue(store),
  ],
);

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('NotificationPreferenceNotifier — initial state', () {
    test('is false when store has no saved preference', () {
      final c = _makeContainer(
        fcm: _FakeFcmService(),
        firestore: _FakeFirestoreService(),
        store: _FakePrefStore(),
      );
      addTearDown(c.dispose);
      expect(c.read(notificationPreferenceProvider), isFalse);
    });

    test('is true when store has saved true', () {
      final c = _makeContainer(
        fcm: _FakeFcmService(),
        firestore: _FakeFirestoreService(),
        store: _FakePrefStore(initial: true),
      );
      addTearDown(c.dispose);
      expect(c.read(notificationPreferenceProvider), isTrue);
    });
  });

  group('NotificationPreferenceNotifier — enable()', () {
    test('requests FCM permission', () async {
      final fcm = _FakeFcmService();
      final c = _makeContainer(
        fcm: fcm,
        firestore: _FakeFirestoreService(),
        store: _FakePrefStore(),
      );
      addTearDown(c.dispose);
      await c.read(notificationPreferenceProvider.notifier).enable('uid-123');
      expect(fcm.permissionRequested, isTrue);
    });

    test('subscribes to donor_updates topic', () async {
      final fcm = _FakeFcmService();
      final c = _makeContainer(
        fcm: fcm,
        firestore: _FakeFirestoreService(),
        store: _FakePrefStore(),
      );
      addTearDown(c.dispose);
      await c.read(notificationPreferenceProvider.notifier).enable('uid-123');
      expect(fcm.subscribedTopics, contains('donor_updates'));
    });

    test('saves FCM token to Firestore', () async {
      final firestore = _FakeFirestoreService();
      final c = _makeContainer(
        fcm: _FakeFcmService(),
        firestore: firestore,
        store: _FakePrefStore(),
      );
      addTearDown(c.dispose);
      await c.read(notificationPreferenceProvider.notifier).enable('uid-123');
      expect(firestore.lastFcmTokenUid, 'uid-123');
      expect(firestore.lastFcmToken, 'test-token-abc');
    });

    test('skips Firestore save when token is null', () async {
      final fcm = _FakeFcmService()..tokenToReturn = null;
      final firestore = _FakeFirestoreService();
      final c = _makeContainer(
        fcm: fcm,
        firestore: firestore,
        store: _FakePrefStore(),
      );
      addTearDown(c.dispose);
      await c.read(notificationPreferenceProvider.notifier).enable('uid-123');
      expect(firestore.lastFcmToken, isNull);
    });

    test('sets state to true', () async {
      final c = _makeContainer(
        fcm: _FakeFcmService(),
        firestore: _FakeFirestoreService(),
        store: _FakePrefStore(),
      );
      addTearDown(c.dispose);
      await c.read(notificationPreferenceProvider.notifier).enable('uid-123');
      expect(c.read(notificationPreferenceProvider), isTrue);
    });

    test('persists true to store', () async {
      final store = _FakePrefStore();
      final c = _makeContainer(
        fcm: _FakeFcmService(),
        firestore: _FakeFirestoreService(),
        store: store,
      );
      addTearDown(c.dispose);
      await c.read(notificationPreferenceProvider.notifier).enable('uid-123');
      expect(store.load(), isTrue);
    });
  });

  group('NotificationPreferenceNotifier — disable()', () {
    test('unsubscribes from donor_updates topic', () async {
      final fcm = _FakeFcmService();
      final c = _makeContainer(
        fcm: fcm,
        firestore: _FakeFirestoreService(),
        store: _FakePrefStore(initial: true),
      );
      addTearDown(c.dispose);
      await c.read(notificationPreferenceProvider.notifier).disable('uid-123');
      expect(fcm.unsubscribedTopics, contains('donor_updates'));
    });

    test('clears FCM token from Firestore', () async {
      final firestore = _FakeFirestoreService();
      final c = _makeContainer(
        fcm: _FakeFcmService(),
        firestore: firestore,
        store: _FakePrefStore(initial: true),
      );
      addTearDown(c.dispose);
      await c.read(notificationPreferenceProvider.notifier).disable('uid-123');
      expect(firestore.lastFcmTokenUid, 'uid-123');
      expect(firestore.lastUpdateFields?['fcmToken'], isNull);
    });

    test('sets state to false', () async {
      final c = _makeContainer(
        fcm: _FakeFcmService(),
        firestore: _FakeFirestoreService(),
        store: _FakePrefStore(initial: true),
      );
      addTearDown(c.dispose);
      await c.read(notificationPreferenceProvider.notifier).disable('uid-123');
      expect(c.read(notificationPreferenceProvider), isFalse);
    });

    test('persists false to store', () async {
      final store = _FakePrefStore(initial: true);
      final c = _makeContainer(
        fcm: _FakeFcmService(),
        firestore: _FakeFirestoreService(),
        store: store,
      );
      addTearDown(c.dispose);
      await c.read(notificationPreferenceProvider.notifier).disable('uid-123');
      expect(store.load(), isFalse);
    });
  });
}
