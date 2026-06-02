// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class ClaimBatchUsecase {
  const ClaimBatchUsecase(this._repository);
  final DriverRepository _repository;
  Future<void> call(String batchId, String driverId) =>
      _repository.claimBatch(batchId, driverId);
}
