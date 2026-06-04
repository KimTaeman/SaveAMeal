import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_profile_repository.dart';

class GetDriverProfileUseCase {
  const GetDriverProfileUseCase(this._repository);
  final DriverProfileRepository _repository;

  Future<DriverProfile> call(String uid) => _repository.getProfile(uid);
}
