import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';

class ConfirmDeliveryUseCase {
  const ConfirmDeliveryUseCase(this._repository);

  final IntakeRepository _repository;

  Future<void> call({required String batchId, required String volunteerId}) =>
      _repository.confirmDelivery(batchId: batchId, volunteerId: volunteerId);
}
