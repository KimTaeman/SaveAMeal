import 'package:saveameal/core/models/user_model.dart' as m;
import 'package:saveameal/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._datasource);

  final AuthRemoteDatasource _datasource;

  @override
  Stream<AppUser?> watchAuthState() =>
      _datasource.watchAuthState().asyncMap((firebaseUser) async {
        if (firebaseUser == null) return null;
        final model = await _datasource.getUser(firebaseUser.uid);
        return model == null
            ? null
            : _toEntity(model, createdAt: firebaseUser.metadata.creationTime);
      });

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async =>
      _toEntity(await _datasource.signIn(email: email, password: password));

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async => _toEntity(
    await _datasource.signUp(
      name: name,
      email: email,
      password: password,
      role: _toModelRole(role),
      phone: phone,
    ),
  );

  @override
  Future<void> signOut() => _datasource.signOut();

  AppUser _toEntity(m.UserModel model, {DateTime? createdAt}) => AppUser(
    uid: model.uid,
    name: model.name,
    email: model.email,
    role: _toDomainRole(model.role),
    createdAt: createdAt,
  );

  UserRole _toDomainRole(m.UserRole r) => switch (r) {
    m.UserRole.donor => UserRole.donor,
    m.UserRole.driver => UserRole.driver,
    m.UserRole.beneficiary => UserRole.beneficiary,
  };

  m.UserRole _toModelRole(UserRole r) => switch (r) {
    UserRole.donor => m.UserRole.donor,
    UserRole.driver => m.UserRole.driver,
    UserRole.beneficiary => m.UserRole.beneficiary,
  };
}
