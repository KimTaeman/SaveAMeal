import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';

class WatchAllBatchesUsecase {
  const WatchAllBatchesUsecase(this._repository);

  final DonorRepository _repository;

  Stream<List<Batch>> call(String donorId) =>
      _repository.watchAllBatches(donorId);
}
