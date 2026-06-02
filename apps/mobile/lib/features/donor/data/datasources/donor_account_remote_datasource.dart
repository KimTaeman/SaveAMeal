import 'package:saveameal/core/models/user_model.dart';
import 'package:saveameal/services/firestore_service.dart';

abstract class DonorAccountRemoteDatasource {
  Future<void> updateUser(String uid, Map<String, dynamic> fields);
  Future<UserModel?> getUser(String uid);
}

class DonorAccountRemoteDatasourceImpl implements DonorAccountRemoteDatasource {
  const DonorAccountRemoteDatasourceImpl(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> fields) =>
      _firestoreService.updateUser(uid, fields);

  @override
  Future<UserModel?> getUser(String uid) => _firestoreService.getUser(uid);
}
