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
      _firestoreService.updateUser(uid, update.toMap());

  @override
  Future<UserModel?> getUser(String uid) => _firestoreService.getUser(uid);
}
