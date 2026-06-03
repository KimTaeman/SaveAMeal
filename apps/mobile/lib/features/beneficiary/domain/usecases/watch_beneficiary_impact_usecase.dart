// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_impact_repository.dart';

class WatchBeneficiaryImpactUsecase {
  const WatchBeneficiaryImpactUsecase(this._repository);

  final BeneficiaryImpactRepository _repository;

  Stream<BeneficiaryImpact> call(String beneficiaryId) =>
      _repository.watchImpact(beneficiaryId);
}
