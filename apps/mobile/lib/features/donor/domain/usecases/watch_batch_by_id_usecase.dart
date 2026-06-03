import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';

class WatchBatchByIdUsecase {
  const WatchBatchByIdUsecase(this._repository);

  final DonorRepository _repository;

  Stream<Batch> call(String batchId) => _repository.watchBatchById(batchId);
}
