import 'package:saveameal/core/models/user_model.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';
import 'package:saveameal/services/firestore_service.dart';

abstract class DonorAccountRemoteDatasource {
  Future<void> updateUser(String uid, UserProfileUpdate update);
  Future<UserModel?> getUser(String uid);
}

class DonorAccountRemoteDatasourceImpl implements DonorAccountRemoteDatasource {
  const DonorAccountRemoteDatasourceImpl(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Future<void> updateUser(String uid, UserProfileUpdate update) =>
      _firestoreService.updateUser(uid, _toFirestoreMap(update));

  @override
  Future<UserModel?> getUser(String uid) => _firestoreService.getUser(uid);
}

Map<String, dynamic> _toFirestoreMap(UserProfileUpdate u) => {
  if (u.name != null) 'name': u.name,
  if (u.phone != null) 'phone': u.phone,
  if (u.location != null) 'location': u.location,
  if (u.photoUrl != null) 'photoUrl': u.photoUrl,
  if (u.orgName != null) 'orgName': u.orgName,
  if (u.managerName != null) 'managerName': u.managerName,
  if (u.streetAddress != null) 'streetAddress': u.streetAddress,
  if (u.bannerUrl != null) 'bannerUrl': u.bannerUrl,
  if (u.operatingHours != null) 'operatingHours': u.operatingHours,
  if (u.surplusTypes != null) 'surplusTypes': u.surplusTypes,
  if (u.latitude != null) 'latitude': u.latitude,
  if (u.longitude != null) 'longitude': u.longitude,
};
