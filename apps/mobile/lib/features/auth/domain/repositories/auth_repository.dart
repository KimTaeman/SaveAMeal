// Pure Dart interface — no Flutter or backend imports.
import 'package:saveameal/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> watchAuthState();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  });

  Future<void> signOut();
}
