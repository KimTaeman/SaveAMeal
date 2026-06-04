import 'package:saveameal/features/beneficiary/data/datasources/beneficiary_impact_remote_datasource.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_impact_repository.dart';

class FirestoreBeneficiaryImpactRepository
    implements BeneficiaryImpactRepository {
  const FirestoreBeneficiaryImpactRepository(this._datasource);

  final BeneficiaryImpactRemoteDatasource _datasource;

  @override
  Stream<BeneficiaryImpact> watchImpact(String beneficiaryId) =>
      _datasource.watchImpact(beneficiaryId);
}
