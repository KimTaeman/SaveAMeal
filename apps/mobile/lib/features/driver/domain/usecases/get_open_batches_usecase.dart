// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class GetOpenBatchesUsecase {
  const GetOpenBatchesUsecase(this._repository);
  final DriverRepository _repository;
  Stream<List<BatchSummary>> call() => _repository.getOpenBatches();
}
