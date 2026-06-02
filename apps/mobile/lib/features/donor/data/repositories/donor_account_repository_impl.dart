import 'package:saveameal/core/models/user_model.dart';
import 'package:saveameal/features/donor/data/datasources/donor_account_remote_datasource.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_account_repository.dart';

class DonorAccountRepositoryImpl implements DonorAccountRepository {
  const DonorAccountRepositoryImpl(this._datasource);

  final DonorAccountRemoteDatasource _datasource;

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> fields) =>
      _datasource.updateUser(uid, fields);

  @override
  Future<UserModel?> getUser(String uid) => _datasource.getUser(uid);
}
