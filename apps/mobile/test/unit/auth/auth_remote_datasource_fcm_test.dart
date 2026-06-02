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

  // All other methods throw — tests should not call them
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
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
    sut = AuthRemoteDatasourceImpl(_FakeAuthService(), firestore, fcm);
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
