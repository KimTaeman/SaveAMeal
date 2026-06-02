// Pure Dart repository interface — zero Flutter or backend imports.
import 'package:saveameal/features/donor/domain/entities/donor_profile.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';

abstract class DonorAccountRepository {
  Future<void> updateUser(String uid, UserProfileUpdate update);
  Future<DonorProfile?> getUser(String uid);
}
