// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/features/beneficiary/domain/entities/incoming_batch.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_repository.dart';

class WatchIncomingBatchUsecase {
  const WatchIncomingBatchUsecase(this._repository);

  final BeneficiaryRepository _repository;

  Stream<List<IncomingBatch>> call(String beneficiaryId) =>
      _repository.watchIncomingBatches(beneficiaryId);
}
