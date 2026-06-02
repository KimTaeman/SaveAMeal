// Pure Dart repository interface — zero Flutter or backend imports.
import 'package:saveameal/core/models/user_model.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';

abstract class DonorAccountRepository {
  Future<void> updateUser(String uid, UserProfileUpdate update);
  Future<UserModel?> getUser(String uid);
}
