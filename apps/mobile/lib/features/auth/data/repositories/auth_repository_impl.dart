import 'package:saveameal/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:saveameal/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._datasource);

  final AuthRemoteDatasource _datasource;

  // TODO: implement AuthRepository methods
}
