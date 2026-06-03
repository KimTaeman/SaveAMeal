import 'package:saveameal/features/driver/domain/repositories/driver_profile_repository.dart';

class UploadAvatarUseCase {
  const UploadAvatarUseCase(this._repository);
  final DriverProfileRepository _repository;

  /// Returns the Firebase Storage download URL for the uploaded image.
  Future<String> call(String uid, String localFilePath) =>
      _repository.uploadAvatar(uid, localFilePath);
}
