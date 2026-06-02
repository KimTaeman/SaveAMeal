// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class GetActiveBatchUsecase {
  const GetActiveBatchUsecase(this._repository);
  final DriverRepository _repository;
  Stream<BatchSummary?> call(String driverId) =>
      _repository.getActiveBatch(driverId);
}
