// Pure Dart — zero Flutter or backend imports.

import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';

class WatchIntakeRequestDetailUseCase {
  const WatchIntakeRequestDetailUseCase(this._repository);

  final IntakeRepository _repository;

  Stream<IntakeRequestDetail?> call(String batchId) =>
      _repository.watchIntakeRequestDetail(batchId);
}
