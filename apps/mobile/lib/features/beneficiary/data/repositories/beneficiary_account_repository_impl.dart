import 'package:saveameal/features/beneficiary/data/datasources/beneficiary_account_remote_datasource.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_org_profile_update.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_profile.dart';
import 'package:saveameal/features/beneficiary/domain/entities/order_history_entry.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_account_repository.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';

class BeneficiaryAccountRepositoryImpl implements BeneficiaryAccountRepository {
  const BeneficiaryAccountRepositoryImpl(this._datasource);

  final BeneficiaryAccountRemoteDatasource _datasource;

  @override
  Stream<BeneficiaryProfile?> watchProfile(String uid) =>
      _datasource.watchProfile(uid).map((model) => model?.toDomain());

  @override
  Future<void> updatePersonalInfo(String uid, UserProfileUpdate update) =>
      _datasource.updatePersonalInfo(uid, update);

  @override
  Future<void> updateOrgProfile(
    String uid,
    BeneficiaryOrgProfileUpdate update,
  ) => _datasource.updateOrgProfile(uid, update);

  @override
  Stream<List<OrderHistoryEntry>> watchOrderHistory(
    String uid, {
    String? cursor,
    int limit = 10,
  }) => throw UnimplementedError();
}
