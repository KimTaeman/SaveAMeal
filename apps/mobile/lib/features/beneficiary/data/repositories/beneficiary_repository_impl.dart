import 'package:saveameal/features/beneficiary/data/datasources/beneficiary_remote_datasource.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_repository.dart';

class BeneficiaryRepositoryImpl implements BeneficiaryRepository {
  const BeneficiaryRepositoryImpl(this._datasource);

  final BeneficiaryRemoteDatasource _datasource;

  // TODO: implement BeneficiaryRepository methods
}
