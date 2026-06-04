import 'dart:typed_data';

import 'package:saveameal/features/driver/domain/repositories/driver_profile_repository.dart';

class UploadAvatarUseCase {
  const UploadAvatarUseCase(this._repository);
  final DriverProfileRepository _repository;

  /// Returns the Firebase Storage download URL for the uploaded image.
  Future<String> call(String uid, Uint8List bytes) =>
      _repository.uploadAvatar(uid, bytes);
}
