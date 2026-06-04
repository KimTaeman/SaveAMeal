import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_org_profile_update.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_account_repository.dart';

class UpdateOrgProfileUseCase {
  const UpdateOrgProfileUseCase(this._repository);
  final BeneficiaryAccountRepository _repository;

  Future<void> call(String uid, BeneficiaryOrgProfileUpdate update) =>
      _repository.updateOrgProfile(uid, update);
}
