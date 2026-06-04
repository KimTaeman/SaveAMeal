import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_profile.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_account_repository.dart';

class WatchBeneficiaryProfileUseCase {
  const WatchBeneficiaryProfileUseCase(this._repository);
  final BeneficiaryAccountRepository _repository;

  Stream<BeneficiaryProfile?> call(String uid) => _repository.watchProfile(uid);
}
