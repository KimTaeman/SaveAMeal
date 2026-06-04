// Pure Dart use case — zero Flutter, Riverpod, or Firestore imports.

import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';

class ConfirmReceiptUseCase {
  const ConfirmReceiptUseCase(this._repository);

  final IntakeRepository _repository;

  Future<void> call({
    required String batchId,
    required String beneficiaryId,
    int? rating,
    String? feedback,
  }) => _repository.confirmReceipt(
    batchId: batchId,
    beneficiaryId: beneficiaryId,
    rating: rating,
    feedback: feedback,
  );
}
