// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_repository.dart';

class RateDeliveryUsecase {
  const RateDeliveryUsecase(this._repository);

  final BeneficiaryRepository _repository;

  Future<void> call({
    required String batchId,
    required int rating,
    String? feedback,
  }) => _repository.rateDelivery(
    batchId: batchId,
    rating: rating,
    feedback: feedback,
  );
}
