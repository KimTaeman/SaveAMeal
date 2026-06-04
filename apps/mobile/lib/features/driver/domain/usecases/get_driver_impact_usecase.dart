import 'package:saveameal/features/driver/domain/entities/driver_impact.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_impact_repository.dart';

class GetDriverImpactUsecase {
  const GetDriverImpactUsecase(this._repository);
  final DriverImpactRepository _repository;

  Future<DriverImpact> call(String uid) => _repository.getDriverImpact(uid);
}
