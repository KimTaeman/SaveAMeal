// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/domain/repositories/auth_repository.dart';

class SignInUsecase {
  const SignInUsecase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String password}) =>
      _repository.signIn(email: email, password: password);
}
