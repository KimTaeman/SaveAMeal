// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class ConfirmPickupUsecase {
  const ConfirmPickupUsecase(this._repository);
  final DriverRepository _repository;
  Future<void> call(String batchId, String photoUrl) =>
      _repository.confirmPickup(batchId, photoUrl);
}
