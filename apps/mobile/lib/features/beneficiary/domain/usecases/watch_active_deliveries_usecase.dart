import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';

class WatchActiveDeliveriesUseCase {
  const WatchActiveDeliveriesUseCase(this._repository);

  final IntakeRepository _repository;

  Stream<List<IntakeRequest>> call(String beneficiaryId) =>
      _repository.watchActiveDeliveries(beneficiaryId);
}
