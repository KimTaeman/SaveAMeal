# Firestore-backed In-App Notifications — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `MockNotificationsRepository` with a Firestore-backed implementation so real FCM-triggered notifications appear in the in-app notification list and persist across device reinstalls.

**Architecture:** Cloud Functions write a notification document to `notifications/{userId}/items/{id}` alongside every FCM send. The Flutter app streams that subcollection via `FirestoreNotificationsRepository` and displays it in the existing `NotificationsScreen` (UI unchanged).

**Tech Stack:** Cloud Firestore (subcollections), Firebase Cloud Functions (TypeScript), flutter_riverpod (StreamNotifier pattern), cloud_firestore Dart package.

---

## File Map

| Action | Path |
|---|---|
| Modify | `apps/mobile/lib/core/constants/firestore_constants.dart` |
| Modify | `apps/mobile/lib/features/notifications/domain/repositories/notifications_repository.dart` |
| Modify | `apps/mobile/lib/features/notifications/data/mock_notifications_repository.dart` |
| Create | `apps/mobile/lib/features/notifications/data/repositories/firestore_notifications_repository.dart` |
| Modify | `apps/mobile/lib/features/notifications/presentation/providers/notifications_provider.dart` |
| Modify | `apps/mobile/test/widget/notifications_screen_test.dart` |
| Modify | `firestore.rules` |
| Modify | `functions/src/onBatchCreated.ts` |
| Modify | `functions/src/onBatchClaimed.ts` |
| Modify | `functions/src/onDeliveryComplete.ts` |

---

## Task 1 — Add Firestore constants

**Files:**
- Modify: `apps/mobile/lib/core/constants/firestore_constants.dart`

- [ ] **Step 1: Add the two new constants**

Replace the file contents with:

```dart
abstract final class FirestoreConstants {
  static const String users = 'users';
  static const String batches = 'batches';
  static const String driverLocations = 'driverLocations';
  static const String impactMetrics = 'impactMetrics';
  static const String globalMetricsId = 'global';
  static const String beneficiaries = 'beneficiaries';
  static const String notifications = 'notifications';
  static const String notificationItems = 'items';
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd apps/mobile && flutter analyze lib/core/constants/firestore_constants.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/lib/core/constants/firestore_constants.dart
git commit -m "feat(notifications): add Firestore collection constants"
```

---

## Task 2 — Update NotificationsRepository interface

**Files:**
- Modify: `apps/mobile/lib/features/notifications/domain/repositories/notifications_repository.dart`

- [ ] **Step 1: Replace file contents**

```dart
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';

abstract interface class NotificationsRepository {
  Stream<List<AppNotification>> watchAll(String uid);
  Future<void> markRead(String uid, String id);
  Future<void> markAllRead(String uid);
}
```

Note: `getAll()` is removed — `watchAll(uid)` replaces it. `markRead` and `markAllRead` now take a `uid` and return `Future<void>`.

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/features/notifications/domain/repositories/notifications_repository.dart
git commit -m "feat(notifications): update repository interface for Firestore streams"
```

---

## Task 3 — Update MockNotificationsRepository

**Files:**
- Modify: `apps/mobile/lib/features/notifications/data/mock_notifications_repository.dart`

- [ ] **Step 1: Replace file contents**

```dart
import 'dart:async';

import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/domain/repositories/notifications_repository.dart';

class MockNotificationsRepository implements NotificationsRepository {
  MockNotificationsRepository() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    _items = [
      AppNotification(
        id: '1',
        type: NotificationType.deliveryArriving,
        title: 'Driver Arriving Soon',
        body: 'Nattapong is 5 minutes away with your delivery.',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      AppNotification(
        id: '2',
        type: NotificationType.matchConfirmed,
        title: 'Match Confirmed! Batch #8492 is assigned to Haven Shelter.',
        body: 'Driver on the way.',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      AppNotification(
        id: '3',
        type: NotificationType.deliverySuccessful,
        title: 'Delivery Successful! Haven Shelter received your bakery batch.',
        body: 'You saved 37.5kg of CO2!',
        timestamp: now.subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      AppNotification(
        id: '4',
        type: NotificationType.deliverySuccessful,
        title: 'Delivery Successful',
        body: '38 portions of bakery goods were dropped off by Nattapong.',
        timestamp: yesterday.copyWith(hour: 14, minute: 45),
        isRead: true,
        actionLabel: 'View Receipt',
        actionBatchId: '8832',
      ),
      AppNotification(
        id: '5',
        type: NotificationType.batchCompleted,
        title: 'Batch #8411 Completed.',
        body: 'Your batch has been completed successfully.',
        timestamp: yesterday.copyWith(hour: 10, minute: 0),
        isRead: true,
      ),
    ];
    _controller.add(List.unmodifiable(_items));
  }

  late List<AppNotification> _items;
  final _controller =
      StreamController<List<AppNotification>>.broadcast();

  @override
  Stream<List<AppNotification>> watchAll(String uid) => _controller.stream;

  @override
  Future<void> markRead(String uid, String id) async {
    _items =
        _items.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<void> markAllRead(String uid) async {
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    _controller.add(List.unmodifiable(_items));
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd apps/mobile && flutter analyze lib/features/notifications/data/mock_notifications_repository.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/lib/features/notifications/data/mock_notifications_repository.dart
git commit -m "feat(notifications): update mock repo for stream-based interface"
```

---

## Task 4 — Create FirestoreNotificationsRepository

**Files:**
- Create: `apps/mobile/lib/features/notifications/data/repositories/firestore_notifications_repository.dart`

- [ ] **Step 1: Write the failing test first**

Create `apps/mobile/test/unit/notifications/firestore_notifications_repository_test.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/notifications/data/repositories/firestore_notifications_repository.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late FirestoreNotificationsRepository repo;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    repo = FirestoreNotificationsRepository(fakeDb);
  });

  Future<void> seedNotification(
    String uid,
    String id,
    String type, {
    bool isRead = false,
    String? actionBatchId,
  }) =>
      fakeDb
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .doc(id)
          .set({
            'type': type,
            'title': 'Test title',
            'body': 'Test body',
            'timestamp': Timestamp.fromDate(DateTime(2024, 1, 1)),
            'isRead': isRead,
            if (actionBatchId != null) 'actionBatchId': actionBatchId,
          });

  test('watchAll emits notifications for the given uid', () async {
    await seedNotification('user1', 'n1', 'new_batch');
    await seedNotification('user1', 'n2', 'driver_assigned');
    await seedNotification('user2', 'n3', 'new_batch');

    final list = await repo.watchAll('user1').first;
    expect(list.length, 2);
    expect(list.map((n) => n.id), containsAll(['n1', 'n2']));
    expect(list.map((n) => n.id), isNot(contains('n3')));
  });

  test('watchAll maps type strings to NotificationType enum', () async {
    await seedNotification('u', 'a', 'new_batch');
    await seedNotification('u', 'b', 'driver_assigned');
    await seedNotification('u', 'c', 'incoming_delivery');
    await seedNotification('u', 'd', 'delivery_arrived');

    final list = await repo.watchAll('u').first;
    final types = {for (final n in list) n.id: n.type};
    expect(types['a'], NotificationType.newBatch);
    expect(types['b'], NotificationType.driverAssigned);
    expect(types['c'], NotificationType.deliveryArriving);
    expect(types['d'], NotificationType.deliverySuccessful);
  });

  test('markRead sets isRead to true in Firestore', () async {
    await seedNotification('u', 'n1', 'new_batch', isRead: false);

    await repo.markRead('u', 'n1');

    final doc =
        await fakeDb.collection('notifications').doc('u').collection('items').doc('n1').get();
    expect(doc.data()?['isRead'], isTrue);
  });

  test('markAllRead sets all items to isRead true', () async {
    await seedNotification('u', 'n1', 'new_batch', isRead: false);
    await seedNotification('u', 'n2', 'driver_assigned', isRead: false);
    await seedNotification('u', 'n3', 'delivery_arrived', isRead: true);

    await repo.markAllRead('u');

    final qs = await fakeDb
        .collection('notifications')
        .doc('u')
        .collection('items')
        .get();
    for (final doc in qs.docs) {
      expect(doc.data()['isRead'], isTrue);
    }
  });
}
```

- [ ] **Step 2: Run the test — confirm it fails with class not found**

```bash
cd apps/mobile && flutter test test/unit/notifications/firestore_notifications_repository_test.dart
```
Expected: compile error — `FirestoreNotificationsRepository` not found.

- [ ] **Step 3: Create the implementation**

Create `apps/mobile/lib/features/notifications/data/repositories/firestore_notifications_repository.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saveameal/core/constants/firestore_constants.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/domain/repositories/notifications_repository.dart';

class FirestoreNotificationsRepository implements NotificationsRepository {
  FirestoreNotificationsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _items(String uid) => _db
      .collection(FirestoreConstants.notifications)
      .doc(uid)
      .collection(FirestoreConstants.notificationItems);

  @override
  Stream<List<AppNotification>> watchAll(String uid) => _items(uid)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((qs) => qs.docs.map(_fromDoc).toList());

  @override
  Future<void> markRead(String uid, String id) =>
      _items(uid).doc(id).update({'isRead': true});

  @override
  Future<void> markAllRead(String uid) async {
    final qs =
        await _items(uid).where('isRead', isEqualTo: false).get();
    if (qs.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in qs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  AppNotification _fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AppNotification(
      id: doc.id,
      type: _typeFrom(data['type'] as String? ?? ''),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool? ?? false,
      actionLabel: data['actionLabel'] as String?,
      actionBatchId: data['actionBatchId'] as String?,
    );
  }

  NotificationType _typeFrom(String type) => switch (type) {
    'new_batch'          => NotificationType.newBatch,
    'driver_assigned'    => NotificationType.driverAssigned,
    'incoming_delivery'  => NotificationType.deliveryArriving,
    'delivery_arrived'   => NotificationType.deliverySuccessful,
    _                    => NotificationType.newBatch,
  };
}
```

- [ ] **Step 4: Check `fake_cloud_firestore` is in pubspec.yaml dev_dependencies**

```bash
grep "fake_cloud_firestore" apps/mobile/pubspec.yaml
```

If missing, add it:
```bash
cd apps/mobile && flutter pub add --dev fake_cloud_firestore
```

- [ ] **Step 5: Run tests — confirm all pass**

```bash
cd apps/mobile && flutter test test/unit/notifications/firestore_notifications_repository_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/notifications/data/repositories/firestore_notifications_repository.dart apps/mobile/test/unit/notifications/firestore_notifications_repository_test.dart apps/mobile/pubspec.yaml apps/mobile/pubspec.lock
git commit -m "feat(notifications): add FirestoreNotificationsRepository with tests"
```

---

## Task 5 — Update notifications_provider.dart

**Files:**
- Modify: `apps/mobile/lib/features/notifications/presentation/providers/notifications_provider.dart`

- [ ] **Step 1: Replace file contents**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/notifications/data/notification_prefs_store.dart';
import 'package:saveameal/features/notifications/data/repositories/firestore_notifications_repository.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/domain/repositories/notifications_repository.dart';

part 'notifications_provider.g.dart';

const _kDonorTypes = {
  NotificationType.matchConfirmed,
  NotificationType.driverAssigned,
  NotificationType.deliverySuccessful,
  NotificationType.batchCompleted,
};

@riverpod
NotificationsRepository notificationsRepository(Ref ref) =>
    FirestoreNotificationsRepository(FirebaseFirestore.instance);

@riverpod
NotificationReadStore notificationReadStore(Ref ref) =>
    HiveNotificationReadStore();

@riverpod
Stream<List<AppNotification>> notificationsStream(Ref ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(notificationsRepositoryProvider).watchAll(uid);
}

@riverpod
class NotificationsNotifier extends _$NotificationsNotifier {
  @override
  List<AppNotification> build() {
    final role = ref.watch(authStateProvider).asData?.value?.role;
    final readStore = ref.watch(notificationReadStoreProvider);
    final readIds = readStore.loadReadIds();
    final all =
        ref.watch(notificationsStreamProvider).asData?.value ?? [];

    final filtered = role == UserRole.donor
        ? all.where((n) => _kDonorTypes.contains(n.type)).toList()
        : all;

    return filtered
        .map((n) => readIds.contains(n.id) ? n.copyWith(isRead: true) : n)
        .toList();
  }

  Future<void> markRead(String id) async {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) return;
    final store = ref.read(notificationReadStoreProvider);
    store.saveReadIds({...store.loadReadIds(), id});
    state =
        state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    await ref.read(notificationsRepositoryProvider).markRead(uid, id);
  }

  Future<void> markAllRead() async {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) return;
    final store = ref.read(notificationReadStoreProvider);
    store.saveReadIds(state.map((n) => n.id).toSet());
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    await ref.read(notificationsRepositoryProvider).markAllRead(uid);
  }
}
```

- [ ] **Step 2: Regenerate Riverpod code**

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```
Expected: `Built with build_runner` — no errors.

- [ ] **Step 3: Run full test suite to catch regressions**

```bash
cd apps/mobile && flutter test
```
Expected: most tests pass. The `notifications_screen_test.dart` will fail — that's expected and fixed in Task 6.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/features/notifications/presentation/providers/ 
git commit -m "feat(notifications): wire Firestore repo into notifier via stream provider"
```

---

## Task 6 — Update notifications_screen_test.dart

**Files:**
- Modify: `apps/mobile/test/widget/notifications_screen_test.dart`

- [ ] **Step 1: Replace the test file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/notifications/data/notification_prefs_store.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
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
      notificationsStreamProvider.overrideWith(
        (ref) => Stream.value(items),
      ),
      authStateProvider.overrideWith(
        (_) => Stream.value(_fakeUser),
      ),
      notificationReadStoreProvider.overrideWith(
        (_) => _InMemoryReadStore(),
      ),
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
```

- [ ] **Step 2: Run the notifications screen tests**

```bash
cd apps/mobile && flutter test test/widget/notifications_screen_test.dart --reporter expanded
```
Expected: `All tests passed!`

- [ ] **Step 3: Run the full test suite**

```bash
cd apps/mobile && flutter test
```
Expected: `All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/test/widget/notifications_screen_test.dart
git commit -m "test(notifications): update widget test for stream-based provider"
```

---

## Task 7 — Add Firestore security rules for notifications

**Files:**
- Modify: `firestore.rules`

- [ ] **Step 1: Add the notifications rule block**

After the `impactMetrics` block (before the closing `}`), add:

```
    // ── notifications ──────────────────────────────────────────────────────────
    // Each user reads and writes only their own notification items.
    // Cloud Functions write these via Admin SDK (bypasses rules).
    match /notifications/{userId}/items/{itemId} {
      allow read:   if isSignedIn() && uid() == userId;
      allow update: if isSignedIn() && uid() == userId
                    && request.resource.data.diff(resource.data)
                         .affectedKeys().hasOnly(['isRead']);
      allow create: if false;
      allow delete: if false;
    }
```

- [ ] **Step 2: Deploy the rules**

```bash
firebase deploy --only firestore:rules
```
Expected: `Deploy complete!`

- [ ] **Step 3: Commit**

```bash
git add firestore.rules
git commit -m "feat(notifications): add Firestore security rules for notifications"
```

---

## Task 8 — Cloud Function: onBatchCreated writes to driver notifications

**Files:**
- Modify: `functions/src/onBatchCreated.ts`

- [ ] **Step 1: Write the failing test**

Create `functions/src/__tests__/onBatchCreated.notifications.test.ts`:

```typescript
import * as admin from 'firebase-admin';

// Initialize once for tests
if (!admin.apps.length) {
  admin.initializeApp({ projectId: 'demo-test' });
}

const db = admin.firestore();

describe('writeNotificationsForDrivers', () => {
  beforeEach(async () => {
    // Seed two driver users
    await db.collection('users').doc('driver1').set({ role: 'driver', name: 'D1' });
    await db.collection('users').doc('driver2').set({ role: 'driver', name: 'D2' });
    await db.collection('users').doc('donor1').set({ role: 'donor', name: 'Donor' });
  });

  afterEach(async () => {
    const collections = ['users', 'notifications'];
    for (const col of collections) {
      const snap = await db.collection(col).get();
      const batch = db.batch();
      snap.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
    }
  });

  it('writes a new_batch notification for each driver', async () => {
    const { writeNotificationsForDrivers } = await import('../onBatchCreated');

    await writeNotificationsForDrivers({
      batchId: 'b1',
      donorName: 'Supermart',
      totalKg: 10,
    });

    const d1 = await db.collection('notifications').doc('driver1').collection('items').get();
    const d2 = await db.collection('notifications').doc('driver2').collection('items').get();

    expect(d1.docs).toHaveLength(1);
    expect(d1.docs[0].data().type).toBe('new_batch');
    expect(d1.docs[0].data().isRead).toBe(false);
    expect(d1.docs[0].data().actionBatchId).toBe('b1');

    expect(d2.docs).toHaveLength(1);

    // donor should NOT get a notification
    const donorSnap = await db.collection('notifications').doc('donor1').collection('items').get();
    expect(donorSnap.docs).toHaveLength(0);
  });
});
```

- [ ] **Step 2: Run the test — confirm it fails**

```bash
cd functions && npm test -- --testPathPattern="onBatchCreated.notifications"
```
Expected: FAIL — `writeNotificationsForDrivers` is not exported.

- [ ] **Step 3: Update onBatchCreated.ts**

Replace `functions/src/onBatchCreated.ts`:

```typescript
import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { computeTotals, formatKg } from './computations';

export async function writeNotificationsForDrivers(params: {
  batchId: string;
  donorName: string;
  totalKg: number;
}): Promise<void> {
  const { batchId, donorName, totalKg } = params;
  const db = admin.firestore();
  const driversSnap = await db
    .collection('users')
    .where('role', '==', 'driver')
    .get();
  if (driversSnap.empty) return;

  const writes = driversSnap.docs.map((doc) =>
    db
      .collection('notifications')
      .doc(doc.id)
      .collection('items')
      .add({
        type: 'new_batch',
        title: 'New pickup available',
        body: `${donorName} · ${formatKg(totalKg)} kg`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        actionBatchId: batchId,
      }),
  );
  await Promise.all(writes);
}

export const onBatchCreated = onDocumentCreated(
  { document: 'batches/{batchId}', region: 'asia-southeast1' },
  async (event) => {
    const batch = event.data?.data();
    if (!batch) return;

    const batchId = event.params.batchId;
    const donorName = (batch['donorName'] as string | undefined) ?? 'A donor';
    const items = (batch['items'] as Array<{ weightKg: number }>) ?? [];
    const { totalKg } = computeTotals(items);

    await admin
      .messaging()
      .send({
        topic: 'new_batch_available',
        notification: {
          title: 'New pickup available',
          body: `${donorName} · ${formatKg(totalKg)} kg`,
        },
        data: { type: 'new_batch', batchId },
      })
      .catch((e) => logger.warn(`onBatchCreated: topic FCM failed — ${e}`));

    await writeNotificationsForDrivers({ batchId, donorName, totalKg })
      .catch((e) => logger.warn(`onBatchCreated: notification write failed — ${e}`));

    logger.info(`onBatchCreated: FCM + notifications sent for batch ${batchId}`);
  },
);
```

- [ ] **Step 4: Run the test — confirm it passes**

```bash
cd functions && npm test -- --testPathPattern="onBatchCreated.notifications"
```
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add functions/src/onBatchCreated.ts functions/src/__tests__/onBatchCreated.notifications.test.ts
git commit -m "feat(notifications): write Firestore notification docs for each driver on batch created"
```

---

## Task 9 — Cloud Function: onBatchClaimed writes to donor notifications

**Files:**
- Modify: `functions/src/onBatchClaimed.ts`

- [ ] **Step 1: Write the failing test**

Create `functions/src/__tests__/onBatchClaimed.notifications.test.ts`:

```typescript
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp({ projectId: 'demo-test' });
}

const db = admin.firestore();

describe('writeDonorNotification', () => {
  afterEach(async () => {
    const snap = await db.collection('notifications').get();
    const batch = db.batch();
    snap.docs.forEach(d => batch.delete(d.ref));
    await batch.commit();
  });

  it('writes a driver_assigned notification to the donor', async () => {
    const { writeDonorNotification } = await import('../onBatchClaimed');

    await writeDonorNotification({ donorId: 'donor1', batchId: 'b1' });

    const items = await db
      .collection('notifications')
      .doc('donor1')
      .collection('items')
      .get();

    expect(items.docs).toHaveLength(1);
    expect(items.docs[0].data().type).toBe('driver_assigned');
    expect(items.docs[0].data().isRead).toBe(false);
    expect(items.docs[0].data().actionBatchId).toBe('b1');
  });

  it('does nothing when donorId is undefined', async () => {
    const { writeDonorNotification } = await import('../onBatchClaimed');

    await writeDonorNotification({ donorId: undefined, batchId: 'b1' });

    const items = await db.collectionGroup('items').get();
    expect(items.docs).toHaveLength(0);
  });
});
```

- [ ] **Step 2: Run the test — confirm it fails**

```bash
cd functions && npm test -- --testPathPattern="onBatchClaimed.notifications"
```
Expected: FAIL — `writeDonorNotification` not exported.

- [ ] **Step 3: Update onBatchClaimed.ts — add exported helper and call it**

In `functions/src/onBatchClaimed.ts`, add the exported helper function and call it at the end of the handler. The full updated file:

```typescript
import * as admin from 'firebase-admin';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { computeTotals, formatKg } from './computations';

export async function writeDonorNotification(params: {
  donorId: string | undefined;
  batchId: string;
}): Promise<void> {
  const { donorId, batchId } = params;
  if (!donorId) return;
  await admin
    .firestore()
    .collection('notifications')
    .doc(donorId)
    .collection('items')
    .add({
      type: 'driver_assigned',
      title: 'Driver is on the way',
      body: 'Your batch is being picked up',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      actionBatchId: batchId,
    });
}

export const onBatchClaimed = onDocumentUpdated(
  { document: 'batches/{batchId}', region: 'asia-southeast1' },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    if (before['status'] === 'claimed' || after['status'] !== 'claimed') return;

    const batchId = event.params.batchId;
    const donorId = after['donorId'] as string | undefined;
    const beneficiaryId = after['beneficiaryId'] as string | undefined;
    const donorName = (after['donorName'] as string | undefined) ?? 'A donor';
    const items = (after['items'] as Array<{ weightKg: number }>) ?? [];
    const { totalKg } = computeTotals(items);

    const db = admin.firestore();

    const [donorSnap, benSnap] = await Promise.all([
      donorId ? db.collection('users').doc(donorId).get() : Promise.resolve(null),
      beneficiaryId ? db.collection('users').doc(beneficiaryId).get() : Promise.resolve(null),
    ]);

    const sends: Promise<void>[] = [];

    const donorToken = donorSnap?.data()?.['fcmToken'] as string | undefined;
    if (donorToken) {
      sends.push(
        admin.messaging()
          .send({
            token: donorToken,
            notification: { title: 'Driver is on the way', body: 'Your batch is being picked up' },
            data: { type: 'driver_assigned', batchId },
          })
          .then(() => undefined)
          .catch((e) => logger.warn(`onBatchClaimed: donor FCM failed — ${e}`)),
      );
    } else if (donorId) {
      logger.warn(`onBatchClaimed: donor ${donorId} has no fcmToken`);
    }

    const benToken = benSnap?.data()?.['fcmToken'] as string | undefined;
    if (benToken) {
      sends.push(
        admin.messaging()
          .send({
            token: benToken,
            notification: {
              title: 'Delivery incoming',
              body: `${formatKg(totalKg)} kg from ${donorName}`,
            },
            data: { type: 'incoming_delivery', batchId },
          })
          .then(() => undefined)
          .catch((e) => logger.warn(`onBatchClaimed: beneficiary FCM failed — ${e}`)),
      );
    } else if (beneficiaryId) {
      logger.warn(`onBatchClaimed: beneficiary ${beneficiaryId} has no fcmToken`);
    }

    await Promise.all(sends);

    await writeDonorNotification({ donorId, batchId })
      .catch((e) => logger.warn(`onBatchClaimed: donor notification write failed — ${e}`));

    logger.info(`onBatchClaimed: notifications dispatched for batch ${batchId}`);
  },
);
```

- [ ] **Step 4: Run the test — confirm it passes**

```bash
cd functions && npm test -- --testPathPattern="onBatchClaimed.notifications"
```
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add functions/src/onBatchClaimed.ts functions/src/__tests__/onBatchClaimed.notifications.test.ts
git commit -m "feat(notifications): write Firestore notification doc for donor on batch claimed"
```

---

## Task 10 — Cloud Function: onDeliveryComplete writes to beneficiary notifications

**Files:**
- Modify: `functions/src/onDeliveryComplete.ts`

- [ ] **Step 1: Write the failing test**

Create `functions/src/__tests__/onDeliveryComplete.notifications.test.ts`:

```typescript
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp({ projectId: 'demo-test' });
}

const db = admin.firestore();

describe('writeBeneficiaryNotification', () => {
  afterEach(async () => {
    const snap = await db.collection('notifications').get();
    const batch = db.batch();
    snap.docs.forEach(d => batch.delete(d.ref));
    await batch.commit();
  });

  it('writes a delivery_arrived notification to the beneficiary', async () => {
    const { writeBeneficiaryNotification } = await import('../onDeliveryComplete');

    await writeBeneficiaryNotification({ beneficiaryId: 'ben1', batchId: 'b1' });

    const items = await db
      .collection('notifications')
      .doc('ben1')
      .collection('items')
      .get();

    expect(items.docs).toHaveLength(1);
    expect(items.docs[0].data().type).toBe('delivery_arrived');
    expect(items.docs[0].data().isRead).toBe(false);
    expect(items.docs[0].data().actionBatchId).toBe('b1');
  });

  it('does nothing when beneficiaryId is undefined', async () => {
    const { writeBeneficiaryNotification } = await import('../onDeliveryComplete');

    await writeBeneficiaryNotification({ beneficiaryId: undefined, batchId: 'b1' });

    const items = await db.collectionGroup('items').get();
    expect(items.docs).toHaveLength(0);
  });
});
```

- [ ] **Step 2: Run the test — confirm it fails**

```bash
cd functions && npm test -- --testPathPattern="onDeliveryComplete.notifications"
```
Expected: FAIL — `writeBeneficiaryNotification` not exported.

- [ ] **Step 3: Add exported helper to onDeliveryComplete.ts**

At the top of `functions/src/onDeliveryComplete.ts` (after the imports), add the exported helper:

```typescript
export async function writeBeneficiaryNotification(params: {
  beneficiaryId: string | undefined;
  batchId: string;
}): Promise<void> {
  const { beneficiaryId, batchId } = params;
  if (!beneficiaryId) return;
  await admin
    .firestore()
    .collection('notifications')
    .doc(beneficiaryId)
    .collection('items')
    .add({
      type: 'delivery_arrived',
      title: 'Food has arrived',
      body: 'Tap to confirm receipt',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      actionBatchId: batchId,
    });
}
```

Then inside the `onDocumentUpdated` handler, after the existing `await Promise.all(ops)`, add:

```typescript
    await writeBeneficiaryNotification({ beneficiaryId, batchId })
      .catch((e) => logger.warn(`onDeliveryComplete: notification write failed — ${e}`));
```

- [ ] **Step 4: Run the test — confirm it passes**

```bash
cd functions && npm test -- --testPathPattern="onDeliveryComplete.notifications"
```
Expected: `PASS`

- [ ] **Step 5: Run all function tests**

```bash
cd functions && npm test
```
Expected: `All test suites passed`

- [ ] **Step 6: Commit**

```bash
git add functions/src/onDeliveryComplete.ts functions/src/__tests__/onDeliveryComplete.notifications.test.ts
git commit -m "feat(notifications): write Firestore notification doc for beneficiary on delivery complete"
```

---

## Task 11 — Build and deploy Cloud Functions

- [ ] **Step 1: Build TypeScript**

```bash
cd functions && npm run build
```
Expected: no errors, `lib/` updated.

- [ ] **Step 2: Deploy**

```bash
cd "C:\Users\Windows 11\SaveAMeal" && firebase deploy --only functions
```
Expected: `Deploy complete!` — all three functions updated in `asia-southeast1`.

- [ ] **Step 3: Verify in Firebase Console**

Open Firebase Console → Functions. Confirm `onBatchCreated`, `onBatchClaimed`, `onDeliveryComplete` are all in `asia-southeast1` with a recent deploy timestamp.

---

## Task 12 — Smoke test end-to-end

- [ ] **Step 1: Sign in as donor, create a batch**

Watch Firestore Console → `notifications` collection. Within a few seconds a `new_batch` document should appear under `notifications/{driverUid}/items/`.

- [ ] **Step 2: Open the app as the driver**

Navigate to the Notifications screen. The "New pickup available" notification should appear.

- [ ] **Step 3: Sign in as donor, watch for driver_assigned**

After a driver claims the batch, check `notifications/{donorUid}/items/` — a `driver_assigned` doc should appear, and the notification should show in the donor's notification page.
