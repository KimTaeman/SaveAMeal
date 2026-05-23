// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/domain/repositories/auth_repository.dart';

class SignUpUsecase {
  const SignUpUsecase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) =>
      _repository.signUp(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
      );
}
