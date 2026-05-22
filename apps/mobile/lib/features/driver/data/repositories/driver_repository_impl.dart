import 'package:saveameal/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class DriverRepositoryImpl implements DriverRepository {
  const DriverRepositoryImpl(this._datasource);

  final DriverRemoteDatasource _datasource;

  // TODO: implement DriverRepository methods
}
