# FCM Push Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire Firebase Cloud Messaging end-to-end — Flutter token registration + notification tap routing, and three TypeScript Cloud Functions that trigger on Firestore document events to send push notifications and update impact metrics.

**Architecture:** `FcmService` (abstract interface + `FirebaseFcmService` impl) wraps `FirebaseMessaging` for testable injection. `AuthRemoteDatasourceImpl` saves the device token to Firestore and subscribes drivers to the `new_batch_available` FCM topic after every login. `NotificationHandler` listens for taps in three app states (foreground/background/terminated) and routes to the correct GoRouter path. Three gen-2 Cloud Functions trigger on Firestore writes: `onBatchCreated` sends a topic message to all drivers, `onBatchClaimed` sends individual token messages to the donor and beneficiary, `onDeliveryComplete` notifies the beneficiary and atomically increments `impactMetrics`.

**Tech Stack:** Flutter (`firebase_messaging ^15.0.0` already in pubspec.yaml), TypeScript Cloud Functions v2 (`firebase-functions ^6.0.0`, `firebase-admin ^12.0.0`), Jest + ts-jest for Cloud Function unit tests.

---

## File Map

**New Flutter files:**
- `apps/mobile/lib/services/fcm_service.dart` — `FcmService` abstract interface + `FirebaseFcmService` impl
- `apps/mobile/lib/services/notification_handler.dart` — three-state tap router with static `routeForType`
- `apps/mobile/test/unit/services/fcm_service_test.dart`
- `apps/mobile/test/unit/services/notification_handler_test.dart`
- `apps/mobile/test/unit/auth/auth_remote_datasource_fcm_test.dart`

**Modified Flutter files:**
- `apps/mobile/lib/core/models/user_model.dart` — add `String? fcmToken` field
- `apps/mobile/lib/services/firestore_service.dart` — add `updateFcmToken` method
- `apps/mobile/lib/services/service_providers.dart` — add `fcmServiceProvider`
- `apps/mobile/lib/features/auth/presentation/providers/auth_provider.dart` — pass `FcmService` to datasource constructor
- `apps/mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart` — inject `FcmService`; add token registration + topic subscribe/unsubscribe
- `apps/mobile/lib/app/app.dart` — `ConsumerWidget` → `ConsumerStatefulWidget`; init `NotificationHandler`
- `apps/mobile/lib/main.dart` — register top-level background message handler

**New Cloud Function files:**
- `functions/package.json`
- `functions/tsconfig.json`
- `functions/src/index.ts`
- `functions/src/computations.ts` — pure helpers (`computeTotals`, `formatKg`)
- `functions/src/onBatchCreated.ts`
- `functions/src/onBatchClaimed.ts`
- `functions/src/onDeliveryComplete.ts`
- `functions/src/__tests__/computations.test.ts`

**Modified config:**
- `firebase.json` — add `functions` block

---

## Task 1: Add `fcmToken` to `UserModel`

**Files:**
- Modify: `apps/mobile/lib/core/models/user_model.dart`
- Regenerate: `apps/mobile/lib/core/models/user_model.freezed.dart`, `user_model.g.dart`

- [ ] **Step 1: Add `fcmToken` field**

Open `apps/mobile/lib/core/models/user_model.dart`. Replace the sealed class with:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

enum UserRole { donor, driver, beneficiary }

enum BeneficiaryStatus { accepting, full }

@freezed
sealed class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String name,
    required String email,
    required UserRole role,
    String? phone,
    String? orgName,
    BeneficiaryStatus? status,
    @Default(0) int points,
    String? fcmToken,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

- [ ] **Step 2: Regenerate Freezed + JSON code**

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```

Expected: ends with `[INFO] Running build completed, took ...s` and no errors. Both `user_model.freezed.dart` and `user_model.g.dart` are updated.

- [ ] **Step 3: Run existing tests**

```bash
cd apps/mobile && flutter test
```

Expected: all previously passing tests still pass.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/core/models/user_model.dart \
        apps/mobile/lib/core/models/user_model.freezed.dart \
        apps/mobile/lib/core/models/user_model.g.dart
git commit -m "feat: add fcmToken field to UserModel"
```

---

## Task 2: Add `updateFcmToken` to `FirestoreService`

**Files:**
- Modify: `apps/mobile/lib/services/firestore_service.dart`

- [ ] **Step 1: Append the new method before the closing `}` of the class**

Open `apps/mobile/lib/services/firestore_service.dart`. Add this method at the very end, before the final `}`:

```dart
  Future<void> updateFcmToken(String uid, String token) =>
      _db.collection(FirestoreConstants.users).doc(uid).update({'fcmToken': token});
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd apps/mobile && flutter analyze lib/services/firestore_service.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/lib/services/firestore_service.dart
git commit -m "feat: add updateFcmToken to FirestoreService"
```

---

## Task 3: Create `FcmService`

**Files:**
- Create: `apps/mobile/lib/services/fcm_service.dart`
- Create: `apps/mobile/test/unit/services/fcm_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `apps/mobile/test/unit/services/fcm_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/services/fcm_service.dart';

// Public fake — also imported by auth_remote_datasource_fcm_test.dart.
class FakeFcmService implements FcmService {
  bool permissionRequested = false;
  String? tokenToReturn;
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

void main() {
  late FakeFcmService sut;

  setUp(() => sut = FakeFcmService());

  test('requestPermission sets flag', () async {
    await sut.requestPermission();
    expect(sut.permissionRequested, isTrue);
  });

  test('getToken returns configured value', () async {
    sut.tokenToReturn = 'test-token-xyz';
    expect(await sut.getToken(), 'test-token-xyz');
  });

  test('subscribeToTopic records topic', () async {
    await sut.subscribeToTopic('new_batch_available');
    expect(sut.subscribedTopics, contains('new_batch_available'));
  });

  test('unsubscribeFromTopic records topic', () async {
    await sut.unsubscribeFromTopic('new_batch_available');
    expect(sut.unsubscribedTopics, contains('new_batch_available'));
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd apps/mobile
flutter test test/unit/services/fcm_service_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:saveameal/services/fcm_service.dart'`

- [ ] **Step 3: Create `fcm_service.dart`**

Create `apps/mobile/lib/services/fcm_service.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

abstract class FcmService {
  Future<void> requestPermission();
  Future<String?> getToken();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
}

class FirebaseFcmService implements FcmService {
  FirebaseFcmService(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<void> requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  @override
  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
cd apps/mobile
flutter test test/unit/services/fcm_service_test.dart
```

Expected: `All 4 tests passed.`

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/services/fcm_service.dart \
        apps/mobile/test/unit/services/fcm_service_test.dart
git commit -m "feat: add FcmService abstract interface and FirebaseFcmService impl"
```

---

## Task 4: Register `fcmServiceProvider`, update `authDatasourceProvider`

**Files:**
- Modify: `apps/mobile/lib/services/service_providers.dart`
- Modify: `apps/mobile/lib/features/auth/presentation/providers/auth_provider.dart`

- [ ] **Step 1: Replace `service_providers.dart` entirely**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/services/auth_service.dart';
import 'package:saveameal/services/fcm_service.dart';
import 'package:saveameal/services/firestore_service.dart';
import 'package:saveameal/services/storage_service.dart';

part 'service_providers.g.dart';

@riverpod
AuthService authService(Ref ref) => AuthService(FirebaseAuth.instance);

@riverpod
FirestoreService firestoreService(Ref ref) =>
    FirestoreService(FirebaseFirestore.instance);

@riverpod
StorageService storageService(Ref ref) =>
    StorageService(FirebaseStorage.instance);

@riverpod
FcmService fcmService(Ref ref) =>
    FirebaseFcmService(FirebaseMessaging.instance);
```

- [ ] **Step 2: Update `authDatasource` provider in `auth_provider.dart`**

Open `apps/mobile/lib/features/auth/presentation/providers/auth_provider.dart`. Replace only the `authDatasource` function:

```dart
@riverpod
AuthRemoteDatasource authDatasource(Ref ref) => AuthRemoteDatasourceImpl(
  ref.watch(authServiceProvider),
  ref.watch(firestoreServiceProvider),
  ref.watch(fcmServiceProvider),
);
```

The rest of `auth_provider.dart` is unchanged.

- [ ] **Step 3: Regenerate service providers**

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```

Expected: `service_providers.g.dart` updated with `fcmServiceProvider`. No errors (the datasource constructor mismatch is expected — fixed in Task 5).

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/services/service_providers.dart \
        apps/mobile/lib/services/service_providers.g.dart \
        apps/mobile/lib/features/auth/presentation/providers/auth_provider.dart \
        apps/mobile/lib/features/auth/presentation/providers/auth_provider.g.dart
git commit -m "feat: add fcmServiceProvider and wire into authDatasourceProvider"
```

---

## Task 5: Update `AuthRemoteDatasourceImpl` for FCM registration

**Files:**
- Modify: `apps/mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart`
- Create: `apps/mobile/test/unit/auth/auth_remote_datasource_fcm_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `apps/mobile/test/unit/auth/auth_remote_datasource_fcm_test.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/core/models/user_model.dart';
import 'package:saveameal/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:saveameal/services/auth_service.dart';
import 'package:saveameal/services/fcm_service.dart';
import 'package:saveameal/services/firestore_service.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeAuthService implements AuthService {
  @override
  Future<UserCredential> signIn(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<UserCredential> signUp(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;
}

class _FakeFirestoreService implements FirestoreService {
  String? lastFcmTokenUid;
  String? lastFcmToken;

  @override
  Future<UserModel?> getUser(String uid) async => null;

  @override
  Future<void> createUser(UserModel user) async {}

  @override
  Future<void> updateFcmToken(String uid, String token) async {
    lastFcmTokenUid = uid;
    lastFcmToken = token;
  }
}

class _FakeFcmService implements FcmService {
  bool permissionRequested = false;
  String? tokenToReturn;
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

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  late _FakeFcmService fcm;
  late _FakeFirestoreService firestore;
  late AuthRemoteDatasourceImpl sut;

  const donorUser = UserModel(
    uid: 'donor-1',
    name: 'Test',
    email: 'test@test.com',
    role: UserRole.donor,
  );

  const driverUser = UserModel(
    uid: 'driver-1',
    name: 'Pong',
    email: 'pong@test.com',
    role: UserRole.driver,
  );

  setUp(() {
    fcm = _FakeFcmService()..tokenToReturn = 'device-token-abc';
    firestore = _FakeFirestoreService();
    sut = AuthRemoteDatasourceImpl(
      _FakeAuthService(),
      firestore,
      fcm,
    );
  });

  group('registerFcmForUser', () {
    test('requests FCM permission', () async {
      await sut.registerFcmForUser(donorUser);
      expect(fcm.permissionRequested, isTrue);
    });

    test('saves FCM token to Firestore', () async {
      await sut.registerFcmForUser(donorUser);
      expect(firestore.lastFcmToken, 'device-token-abc');
      expect(firestore.lastFcmTokenUid, 'donor-1');
    });

    test('skips token save when getToken returns null', () async {
      fcm.tokenToReturn = null;
      await sut.registerFcmForUser(donorUser);
      expect(firestore.lastFcmToken, isNull);
    });

    test('donor does NOT subscribe to new_batch_available', () async {
      await sut.registerFcmForUser(donorUser);
      expect(fcm.subscribedTopics, isEmpty);
    });

    test('driver subscribes to new_batch_available', () async {
      await sut.registerFcmForUser(driverUser);
      expect(fcm.subscribedTopics, contains('new_batch_available'));
    });
  });

  group('signOut', () {
    test('always unsubscribes from new_batch_available', () async {
      await sut.signOut();
      expect(fcm.unsubscribedTopics, contains('new_batch_available'));
    });
  });
}
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
cd apps/mobile
flutter test test/unit/auth/auth_remote_datasource_fcm_test.dart
```

Expected: FAIL — `AuthRemoteDatasourceImpl` takes 2 positional args, `registerFcmForUser` doesn't exist yet.

- [ ] **Step 3: Replace `auth_remote_datasource.dart`**

Replace `apps/mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart` entirely:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saveameal/core/models/user_model.dart';
import 'package:saveameal/services/auth_service.dart';
import 'package:saveameal/services/fcm_service.dart';
import 'package:saveameal/services/firestore_service.dart';

abstract class AuthRemoteDatasource {
  Stream<User?> watchAuthState();

  Future<UserModel> signIn({required String email, required String password});

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  });

  Future<void> signOut();

  Future<UserModel?> getUser(String uid);
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  const AuthRemoteDatasourceImpl(
    this._authService,
    this._firestoreService,
    this._fcmService,
  );

  final AuthService _authService;
  final FirestoreService _firestoreService;
  final FcmService _fcmService;

  @override
  Stream<User?> watchAuthState() => _authService.authStateChanges;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _authService.signIn(email, password);
    final model = await _firestoreService.getUser(cred.user!.uid);
    if (model == null) {
      throw Exception('User document not found for uid: ${cred.user!.uid}');
    }
    await registerFcmForUser(model);
    return model;
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    final cred = await _authService.signUp(email, password);
    final uid = cred.user!.uid;
    final model = UserModel(
      uid: uid,
      name: name,
      email: email,
      role: role,
      phone: phone,
    );
    await _firestoreService.createUser(model);
    await registerFcmForUser(model);
    return model;
  }

  @override
  Future<void> signOut() async {
    await _fcmService.unsubscribeFromTopic('new_batch_available');
    await _authService.signOut();
  }

  @override
  Future<UserModel?> getUser(String uid) => _firestoreService.getUser(uid);

  // Registers the device FCM token and subscribes drivers to the broadcast
  // topic. Exposed (not private) so test subclasses can call it directly.
  Future<void> registerFcmForUser(UserModel model) async {
    await _fcmService.requestPermission();
    final token = await _fcmService.getToken();
    if (token != null) {
      await _firestoreService.updateFcmToken(model.uid, token);
    }
    if (model.role == UserRole.driver) {
      await _fcmService.subscribeToTopic('new_batch_available');
    }
  }
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
cd apps/mobile
flutter test test/unit/auth/auth_remote_datasource_fcm_test.dart
```

Expected: `All 6 tests passed.`

- [ ] **Step 5: Run full test suite**

```bash
cd apps/mobile && flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart \
        apps/mobile/test/unit/auth/auth_remote_datasource_fcm_test.dart
git commit -m "feat: FCM token registration and topic subscribe/unsubscribe on auth"
```

---

## Task 6: Create `NotificationHandler`, update `App` and `main.dart`

**Files:**
- Create: `apps/mobile/lib/services/notification_handler.dart`
- Create: `apps/mobile/test/unit/services/notification_handler_test.dart`
- Modify: `apps/mobile/lib/app/app.dart`
- Modify: `apps/mobile/lib/main.dart`

- [ ] **Step 1: Write the failing test**

Create `apps/mobile/test/unit/services/notification_handler_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/services/notification_handler.dart';

void main() {
  group('NotificationHandler.routeForType', () {
    test('new_batch → /driver', () {
      expect(NotificationHandler.routeForType('new_batch'), '/driver');
    });

    test('driver_assigned → /donor', () {
      expect(NotificationHandler.routeForType('driver_assigned'), '/donor');
    });

    test('incoming_delivery → /beneficiary', () {
      expect(
        NotificationHandler.routeForType('incoming_delivery'),
        '/beneficiary',
      );
    });

    test('delivery_arrived → /beneficiary', () {
      expect(
        NotificationHandler.routeForType('delivery_arrived'),
        '/beneficiary',
      );
    });

    test('unknown type → null', () {
      expect(NotificationHandler.routeForType('something_else'), isNull);
    });

    test('null → null', () {
      expect(NotificationHandler.routeForType(null), isNull);
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd apps/mobile
flutter test test/unit/services/notification_handler_test.dart
```

Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Create `notification_handler.dart`**

Create `apps/mobile/lib/services/notification_handler.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/core/logging/app_logger.dart';

class NotificationHandler {
  NotificationHandler(this._router);

  final GoRouter _router;

  void init() {
    // Foreground: app is open and visible.
    // Firestore real-time streams already update the UI, so we just log.
    FirebaseMessaging.onMessage.listen((message) {
      AppLogger.info(
        'FCM foreground: ${message.notification?.title} '
        '(type=${message.data["type"]})',
      );
    });

    // Background tap: app was minimized, user tapped the system notification.
    FirebaseMessaging.onMessageOpenedApp.listen(_navigate);

    // Terminated tap: app was closed, user tapped to open it.
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((message) { if (message != null) _navigate(message); });
  }

  void _navigate(RemoteMessage message) {
    final route = routeForType(message.data['type'] as String?);
    if (route != null) _router.go(route);
  }

  /// Maps a notification `data.type` value to a GoRouter path.
  /// Returns `null` for unknown or missing types (no navigation).
  static String? routeForType(String? type) {
    switch (type) {
      case 'new_batch':
        return '/driver';
      case 'driver_assigned':
        return '/donor';
      case 'incoming_delivery':
      case 'delivery_arrived':
        return '/beneficiary';
      default:
        return null;
    }
  }
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
cd apps/mobile
flutter test test/unit/services/notification_handler_test.dart
```

Expected: `All 6 tests passed.`

- [ ] **Step 5: Update `main.dart`**

Replace `apps/mobile/lib/main.dart` entirely:

```dart
// ignore: unused_import — uncomment FirestoreEmulator line below to activate
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:saveameal/app/app.dart';
import 'package:saveameal/firebase_options.dart';

/// Top-level function required by Firebase Messaging — must NOT be a class
/// method. Runs in a separate isolate when a notification arrives while the
/// app is terminated.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // No UI — the system tray already shows the notification.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Must be called before runApp.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (kDebugMode) {
    // Toggle: comment the line below to use live Firestore instead of the emulator.
    // Start emulator: firebase emulators:start --only firestore
    // Seed data:      cd tools/seed && npm run seed:clean
    // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }

  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<dynamic>('donor_batches'),
    Hive.openBox<dynamic>('donor_metrics'),
  ]);

  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(const ProviderScope(child: App()));
}
```

- [ ] **Step 6: Update `app.dart`**

Replace `apps/mobile/lib/app/app.dart` entirely:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saveameal/app/router.dart';
import 'package:saveameal/services/notification_handler.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    // addPostFrameCallback ensures the router widget tree is mounted before
    // getInitialMessage() can attempt navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationHandler(ref.read(routerProvider)).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SaveAMeal',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
```

- [ ] **Step 7: Run full test suite and analyze**

```bash
cd apps/mobile
flutter analyze
flutter test
```

Expected: `No issues found!` and all tests pass.

- [ ] **Step 8: Commit**

```bash
git add apps/mobile/lib/services/notification_handler.dart \
        apps/mobile/test/unit/services/notification_handler_test.dart \
        apps/mobile/lib/app/app.dart \
        apps/mobile/lib/main.dart
git commit -m "feat: NotificationHandler routes FCM taps; wire background handler in main"
```

---

## Task 7: Cloud Functions scaffold + computations module

**Files:**
- Create: `functions/package.json`
- Create: `functions/tsconfig.json`
- Create: `functions/src/index.ts`
- Create: `functions/src/computations.ts`
- Create: `functions/src/__tests__/computations.test.ts`
- Create: `functions/src/onBatchCreated.ts` (stub)
- Create: `functions/src/onBatchClaimed.ts` (stub)
- Create: `functions/src/onDeliveryComplete.ts` (stub)
- Modify: `firebase.json`

- [ ] **Step 1: Write the failing test**

Create `functions/src/__tests__/computations.test.ts`:

```typescript
import { computeTotals, formatKg } from '../computations';

describe('computeTotals', () => {
  it('sums weightKg and derives meals + co2e at 2.5×', () => {
    const result = computeTotals([{ weightKg: 4 }, { weightKg: 6 }]);
    expect(result.totalKg).toBeCloseTo(10);
    expect(result.totalMeals).toBeCloseTo(25);
    expect(result.totalCo2e).toBeCloseTo(25);
  });

  it('handles empty array', () => {
    const result = computeTotals([]);
    expect(result.totalKg).toBe(0);
    expect(result.totalMeals).toBe(0);
    expect(result.totalCo2e).toBe(0);
  });

  it('treats undefined weightKg as 0', () => {
    const result = computeTotals([{ weightKg: undefined as unknown as number }]);
    expect(result.totalKg).toBe(0);
  });
});

describe('formatKg', () => {
  it('formats to one decimal place', () => {
    expect(formatKg(8.5)).toBe('8.5');
    expect(formatKg(10)).toBe('10.0');
    expect(formatKg(0)).toBe('0.0');
  });
});
```

- [ ] **Step 2: Create `functions/package.json`**

```json
{
  "name": "functions",
  "scripts": {
    "build": "tsc",
    "test": "jest"
  },
  "engines": { "node": "20" },
  "main": "lib/index.js",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^6.0.0"
  },
  "devDependencies": {
    "@types/jest": "^29.0.0",
    "@types/node": "^20.0.0",
    "jest": "^29.0.0",
    "ts-jest": "^29.0.0",
    "typescript": "^5.0.0"
  },
  "jest": {
    "preset": "ts-jest",
    "testEnvironment": "node",
    "testMatch": ["**/__tests__/**/*.test.ts"]
  },
  "private": true
}
```

- [ ] **Step 3: Create `functions/tsconfig.json`**

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2017"
  },
  "compileOnSave": true,
  "include": ["src"]
}
```

- [ ] **Step 4: Create `functions/src/computations.ts`**

```typescript
export interface BatchItem {
  weightKg: number;
}

export interface Totals {
  totalKg: number;
  totalMeals: number;
  totalCo2e: number;
}

export function computeTotals(items: BatchItem[]): Totals {
  const totalKg = items.reduce((sum, i) => sum + (i.weightKg ?? 0), 0);
  return {
    totalKg,
    totalMeals: totalKg * 2.5,
    totalCo2e: totalKg * 2.5,
  };
}

export function formatKg(kg: number): string {
  return kg.toFixed(1);
}
```

- [ ] **Step 5: Create stub function files so TypeScript compiles**

Create `functions/src/onBatchCreated.ts`:
```typescript
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
export const onBatchCreated = onDocumentCreated('batches/{batchId}', async () => {});
```

Create `functions/src/onBatchClaimed.ts`:
```typescript
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
export const onBatchClaimed = onDocumentUpdated('batches/{batchId}', async () => {});
```

Create `functions/src/onDeliveryComplete.ts`:
```typescript
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
export const onDeliveryComplete = onDocumentUpdated('batches/{batchId}', async () => {});
```

- [ ] **Step 6: Create `functions/src/index.ts`**

```typescript
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

export { onBatchCreated } from './onBatchCreated';
export { onBatchClaimed } from './onBatchClaimed';
export { onDeliveryComplete } from './onDeliveryComplete';
```

- [ ] **Step 7: Create `functions/.gitignore`**

Create `functions/.gitignore`:

```
lib/
node_modules/
```

- [ ] **Step 8: Install dependencies and run test**

```bash
cd functions && npm install && npm test
```

Expected output:
```
PASS src/__tests__/computations.test.ts
  computeTotals
    ✓ sums weightKg and derives meals + co2e at 2.5×
    ✓ handles empty array
    ✓ treats undefined weightKg as 0
  formatKg
    ✓ formats to one decimal place

Tests: 4 passed, 4 total
```

- [ ] **Step 9: Update `firebase.json`**

Replace the entire `firebase.json` at repo root:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log",
        "*.local"
      ]
    }
  ]
}
```

- [ ] **Step 10: Commit**

```bash
cd ..
git add functions/.gitignore functions/package.json functions/tsconfig.json \
        functions/src/ firebase.json
git commit -m "feat: scaffold Cloud Functions with computations module and jest tests"
```

---

## Task 8: `onBatchCreated` — notify all drivers of a new pickup

**Files:**
- Modify: `functions/src/onBatchCreated.ts`

- [ ] **Step 1: Replace the stub**

Replace `functions/src/onBatchCreated.ts`:

```typescript
import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { computeTotals, formatKg } from './computations';

export const onBatchCreated = onDocumentCreated(
  'batches/{batchId}',
  async (event) => {
    const batch = event.data?.data();
    if (!batch) return;

    const batchId = event.params.batchId;
    const donorName = (batch['donorName'] as string | undefined) ?? 'A donor';
    const items = (batch['items'] as Array<{ weightKg: number }>) ?? [];
    const { totalKg } = computeTotals(items);

    await admin.messaging().send({
      topic: 'new_batch_available',
      notification: {
        title: 'New pickup available',
        body: `${donorName} · ${formatKg(totalKg)} kg`,
      },
      data: { type: 'new_batch', batchId },
    });

    logger.info(`onBatchCreated: topic msg sent for batch ${batchId}`);
  },
);
```

- [ ] **Step 2: Build**

```bash
cd functions && npm run build
```

Expected: Compiles to `lib/` with no errors.

- [ ] **Step 3: Commit**

```bash
cd ..
git add functions/src/onBatchCreated.ts
git commit -m "feat: onBatchCreated — broadcast new pickup to all drivers via FCM topic"
```

---

## Task 9: `onBatchClaimed` — notify donor and beneficiary

**Files:**
- Modify: `functions/src/onBatchClaimed.ts`

- [ ] **Step 1: Replace the stub**

Replace `functions/src/onBatchClaimed.ts`:

```typescript
import * as admin from 'firebase-admin';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { computeTotals, formatKg } from './computations';

export const onBatchClaimed = onDocumentUpdated(
  'batches/{batchId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Guard: only fire on the open → claimed transition.
    if (before['status'] === 'claimed' || after['status'] !== 'claimed') return;

    const batchId = event.params.batchId;
    const donorId = after['donorId'] as string | undefined;
    const beneficiaryId = after['beneficiaryId'] as string | undefined;
    const donorName = (after['donorName'] as string | undefined) ?? 'A donor';
    const items = (after['items'] as Array<{ weightKg: number }>) ?? [];
    const { totalKg } = computeTotals(items);

    const db = admin.firestore();
    const sends: Promise<void>[] = [];

    // Notify donor.
    if (donorId) {
      const donorSnap = await db.collection('users').doc(donorId).get();
      const donorToken = donorSnap.data()?.['fcmToken'] as string | undefined;
      if (donorToken) {
        sends.push(
          admin.messaging()
            .send({
              token: donorToken,
              notification: {
                title: 'Driver is on the way',
                body: 'Your batch is being picked up',
              },
              data: { type: 'driver_assigned', batchId },
            })
            .then(() => undefined)
            .catch((e) => logger.warn(`onBatchClaimed: donor FCM failed — ${e}`)),
        );
      } else {
        logger.warn(`onBatchClaimed: donor ${donorId} has no fcmToken`);
      }
    }

    // Notify beneficiary.
    if (beneficiaryId) {
      const benSnap = await db.collection('users').doc(beneficiaryId).get();
      const benToken = benSnap.data()?.['fcmToken'] as string | undefined;
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
      } else {
        logger.warn(`onBatchClaimed: beneficiary ${beneficiaryId} has no fcmToken`);
      }
    }

    await Promise.all(sends);
    logger.info(`onBatchClaimed: notifications dispatched for batch ${batchId}`);
  },
);
```

- [ ] **Step 2: Build**

```bash
cd functions && npm run build
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd ..
git add functions/src/onBatchClaimed.ts
git commit -m "feat: onBatchClaimed — notify donor and beneficiary when driver accepts"
```

---

## Task 10: `onDeliveryComplete` — notify beneficiary + update impact metrics

**Files:**
- Modify: `functions/src/onDeliveryComplete.ts`

- [ ] **Step 1: Replace the stub**

Replace `functions/src/onDeliveryComplete.ts`:

```typescript
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { computeTotals } from './computations';

export const onDeliveryComplete = onDocumentUpdated(
  'batches/{batchId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Guard: only fire on the * → delivered transition.
    if (before['status'] === 'delivered' || after['status'] !== 'delivered') return;

    const batchId = event.params.batchId;
    const beneficiaryId = after['beneficiaryId'] as string | undefined;
    const donorId = after['donorId'] as string | undefined;
    const items = (after['items'] as Array<{ weightKg: number }>) ?? [];
    const { totalKg, totalMeals, totalCo2e } = computeTotals(items);

    const db = admin.firestore();
    const ops: Promise<unknown>[] = [];

    // Notify beneficiary to confirm receipt.
    if (beneficiaryId) {
      const benSnap = await db.collection('users').doc(beneficiaryId).get();
      const benToken = benSnap.data()?.['fcmToken'] as string | undefined;
      if (benToken) {
        ops.push(
          admin.messaging()
            .send({
              token: benToken,
              notification: {
                title: 'Food has arrived',
                body: 'Tap to confirm receipt',
              },
              data: { type: 'delivery_arrived', batchId },
            })
            .catch((e) => logger.warn(`onDeliveryComplete: FCM failed — ${e}`)),
        );
      } else {
        logger.warn(`onDeliveryComplete: beneficiary ${beneficiaryId} has no fcmToken`);
      }
    }

    // Atomically increment impactMetrics for the donor and globally.
    const increment = {
      totalKg: FieldValue.increment(totalKg),
      totalMeals: FieldValue.increment(totalMeals),
      totalCo2e: FieldValue.increment(totalCo2e),
    };

    if (donorId) {
      ops.push(
        db.collection('impactMetrics').doc(donorId).set(increment, { merge: true }),
      );
    }
    ops.push(
      db.collection('impactMetrics').doc('global').set(increment, { merge: true }),
    );

    await Promise.all(ops);
    logger.info(
      `onDeliveryComplete: batch ${batchId} — ` +
      `${totalKg} kg, ${totalMeals} meals, ${totalCo2e} kg CO₂e`,
    );
  },
);
```

- [ ] **Step 2: Build and run all tests**

```bash
cd functions
npm run build
npm test
```

Expected: Build succeeds. All 4 jest tests pass.

- [ ] **Step 3: Run final Flutter test suite**

```bash
cd ../apps/mobile && flutter test
```

Expected: All tests pass.

- [ ] **Step 4: Final commit**

```bash
cd ../..
git add functions/src/onDeliveryComplete.ts
git commit -m "feat: onDeliveryComplete — notify beneficiary and update impactMetrics"
```

---

## Deployment

```bash
# From repo root:
cd functions && npm run build && cd ..
firebase deploy --only functions
```

**Prerequisites before deploying:**
1. Firebase project must be on the **Blaze (pay-as-you-go) plan** — Cloud Functions won't deploy on the free Spark plan.
2. **iOS only**: Upload APNs Auth Key in Firebase Console → Project Settings → Cloud Messaging → iOS app. Without this, iOS devices receive no push notifications.

---

## Manual Verification Checklist

After all 10 tasks are merged and functions deployed, verify in order:

1. **Token registration**: Log in as a donor → check Firestore `users/{uid}` for `fcmToken` field populated.
2. **Topic subscription**: Log in as a driver → Firebase Console → Messaging → Topics → `new_batch_available` shows subscriber count > 0.
3. **Donor → Driver notification**: Create a batch as the donor. Driver device receives "New pickup available" push within seconds.
4. **Driver → Donor + Beneficiary notifications**: Accept a job as the driver. Both donor device and beneficiary device receive their respective notifications.
5. **Delivery → Beneficiary notification**: Mark delivery as delivered. Beneficiary device receives "Food has arrived".
6. **Impact metrics**: After delivery, `impactMetrics/{donorId}` and `impactMetrics/global` in Firestore show incremented `totalKg`, `totalMeals`, `totalCo2e`.
7. **Tap routing from background**: Minimize app, receive a notification, tap it → app foregrounds and navigates to the correct screen.
8. **Tap routing from terminated**: Force-close the app, receive a notification, tap it → app opens and navigates correctly.
