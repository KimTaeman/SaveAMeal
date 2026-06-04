import 'package:saveameal/features/beneficiary/data/datasources/beneficiary_remote_datasource.dart';
import 'package:saveameal/features/beneficiary/domain/entities/incoming_batch.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_repository.dart';

class BeneficiaryRepositoryImpl implements BeneficiaryRepository {
  const BeneficiaryRepositoryImpl(this._datasource);

  final BeneficiaryRemoteDatasource _datasource;

  @override
  Stream<List<IncomingBatch>> watchIncomingBatches(String beneficiaryId) =>
      // TODO: map raw maps to IncomingBatch entities once backend is decided.
      _datasource.watchIncomingBatches(beneficiaryId).map((_) => []);

  @override
  Future<void> rateDelivery({
    required String batchId,
    required int rating,
    String? feedback,
  }) => _datasource.rateDelivery(
    batchId: batchId,
    rating: rating,
    feedback: feedback,
  );
}
