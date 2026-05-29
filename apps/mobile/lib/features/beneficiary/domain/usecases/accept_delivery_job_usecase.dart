import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';

class AcceptDeliveryJobUseCase {
  const AcceptDeliveryJobUseCase(this._repository);

  final IntakeRepository _repository;

  Future<void> call({
    required String batchId,
    required String volunteerId,
    required String volunteerName,
  }) => _repository.acceptDeliveryJob(
    batchId: batchId,
    volunteerId: volunteerId,
    volunteerName: volunteerName,
  );
}
