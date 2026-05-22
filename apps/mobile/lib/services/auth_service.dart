import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Auth. All methods throw [UnimplementedError] until wired up.
class AuthService {
  // TODO: inject FirebaseAuth instance

  /// Emits the current [User] (or null) whenever auth state changes.
  Stream<User?> get authStateChanges =>
      // TODO: implement
      throw UnimplementedError('authStateChanges not implemented');

  /// Signs the user in with email and password.
  Future<UserCredential> signIn(String email, String password) =>
      // TODO: implement
      throw UnimplementedError('signIn not implemented');

  /// Creates a new account with email and password.
  Future<UserCredential> signUp(String email, String password) =>
      // TODO: implement
      throw UnimplementedError('signUp not implemented');

  /// Signs the current user out.
  Future<void> signOut() =>
      // TODO: implement
      throw UnimplementedError('signOut not implemented');

  /// Returns the currently signed-in [User], or null if signed out.
  User? get currentUser =>
      // TODO: implement
      throw UnimplementedError('currentUser not implemented');
}
