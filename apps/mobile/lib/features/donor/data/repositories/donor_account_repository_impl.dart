import 'package:saveameal/core/models/user_model.dart';
import 'package:saveameal/features/donor/data/datasources/donor_account_remote_datasource.dart';
import 'package:saveameal/features/donor/domain/entities/donor_profile.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_account_repository.dart';

class DonorAccountRepositoryImpl implements DonorAccountRepository {
  const DonorAccountRepositoryImpl(this._datasource);

  final DonorAccountRemoteDatasource _datasource;

  @override
  Future<void> updateUser(String uid, UserProfileUpdate update) =>
      _datasource.updateUser(uid, update);

  @override
  Future<DonorProfile?> getUser(String uid) async =>
      _toDomain(await _datasource.getUser(uid));

  DonorProfile? _toDomain(UserModel? model) {
    if (model == null) return null;
    return DonorProfile(
      uid: model.uid,
      name: model.name,
      email: model.email,
      role: model.role.name,
      phone: model.phone,
      location: model.location,
      photoUrl: model.photoUrl,
      orgName: model.orgName,
      managerName: model.managerName,
      streetAddress: model.streetAddress,
      bannerUrl: model.bannerUrl,
      operatingHours: model.operatingHours,
      surplusTypes: model.surplusTypes,
      latitude: model.latitude,
      longitude: model.longitude,
    );
  }
}
