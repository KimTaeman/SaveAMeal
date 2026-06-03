import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_profile_repository.dart';

class UpdateDriverProfileUseCase {
  const UpdateDriverProfileUseCase(this._repository);
  final DriverProfileRepository _repository;

  Future<void> call(DriverProfile profile) =>
      _repository.updateProfile(profile);
}
