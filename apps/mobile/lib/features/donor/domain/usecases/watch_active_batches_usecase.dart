// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';

class WatchActiveBatchesUsecase {
  const WatchActiveBatchesUsecase(this._repository);

  final DonorRepository _repository;

  Stream<List<Batch>> call(String donorId) =>
      _repository.watchActiveBatches(donorId);
}
