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
  // topic. Exposed (not private) so test code can call it directly.
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
