import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_account_repository.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';

class UpdatePersonalInfoUseCase {
  const UpdatePersonalInfoUseCase(this._repository);
  final BeneficiaryAccountRepository _repository;

  Future<void> call(String uid, UserProfileUpdate update) =>
      _repository.updatePersonalInfo(uid, update);
}
