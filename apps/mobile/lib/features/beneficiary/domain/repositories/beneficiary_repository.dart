// Pure Dart interface — no Flutter or backend imports.
import 'package:saveameal/features/beneficiary/domain/entities/incoming_batch.dart';

abstract class BeneficiaryRepository {
  Stream<List<IncomingBatch>> watchIncomingBatches(String beneficiaryId);

  Future<void> rateDelivery({
    required String batchId,
    required int rating,
    String? feedback,
  });
}
