// Pure Dart repository interface — zero Flutter or backend imports.
import 'package:saveameal/core/models/user_model.dart';

abstract class DonorAccountRepository {
  Future<void> updateUser(String uid, Map<String, dynamic> fields);
  Future<UserModel?> getUser(String uid);
}
