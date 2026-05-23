import 'package:firebase_auth/firebase_auth.dart';
import 'package:saveameal/core/models/user_model.dart';
import 'package:saveameal/services/auth_service.dart';
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
  const AuthRemoteDatasourceImpl(this._authService, this._firestoreService);

  final AuthService _authService;
  final FirestoreService _firestoreService;

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
    return model;
  }

  @override
  Future<void> signOut() => _authService.signOut();

  @override
  Future<UserModel?> getUser(String uid) => _firestoreService.getUser(uid);
}
