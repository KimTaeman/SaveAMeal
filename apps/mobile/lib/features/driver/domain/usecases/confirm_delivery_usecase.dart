// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class ConfirmDeliveryUsecase {
  const ConfirmDeliveryUsecase(this._repository);
  final DriverRepository _repository;
  Future<void> call(String batchId, String? notes) =>
      _repository.confirmDelivery(batchId, notes);
}
