import 'package:saveameal/features/donor/data/datasources/donor_remote_datasource.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';

class DonorRepositoryImpl implements DonorRepository {
  const DonorRepositoryImpl(this._datasource);

  final DonorRemoteDatasource _datasource;

  // TODO: implement DonorRepository methods
}
