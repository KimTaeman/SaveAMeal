import 'dart:async';

abstract class BeneficiaryRemoteDatasource {
  /// Returns a stream of raw batch maps for the given beneficiary.
  Stream<List<Map<String, dynamic>>> watchIncomingBatches(String beneficiaryId);

  /// Submits a delivery rating for the given batch.
  Future<void> rateDelivery({
    required String batchId,
    required int rating,
    String? feedback,
  });
}

class BeneficiaryRemoteDatasourceImpl implements BeneficiaryRemoteDatasource {
  // TODO: inject FirestoreService once backend is decided.

  @override
  Stream<List<Map<String, dynamic>>> watchIncomingBatches(
    String beneficiaryId,
  ) => Stream.value([]);

  @override
  Future<void> rateDelivery({
    required String batchId,
    required int rating,
    String? feedback,
  }) => Future.value();
}
