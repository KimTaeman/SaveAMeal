import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';

class ToggleIntakeStatusUseCase {
  const ToggleIntakeStatusUseCase(this._repository);

  final IntakeRepository _repository;

  Future<void> call({
    required String beneficiaryId,
    required BeneficiaryIntakeAvailability availability,
  }) => _repository.toggleIntakeStatus(
    beneficiaryId: beneficiaryId,
    availability: availability,
  );
}
