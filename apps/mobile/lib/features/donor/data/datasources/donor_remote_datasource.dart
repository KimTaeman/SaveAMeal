import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/core/models/beneficiary_model.dart';
import 'package:saveameal/core/models/impact_metrics_model.dart';
import 'package:saveameal/services/firestore_service.dart';

abstract class DonorRemoteDatasource {
  Stream<List<BatchModel>> watchActiveBatches(String donorId);
  Stream<ImpactMetricsModel> watchMetrics(String donorId);
  Future<void> createBatch(BatchModel batch);
  Stream<List<BeneficiaryModel>> getBeneficiaries();
}

class DonorRemoteDatasourceImpl implements DonorRemoteDatasource {
  const DonorRemoteDatasourceImpl(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Stream<List<BatchModel>> watchActiveBatches(String donorId) =>
      _firestoreService.watchActiveBatchesForDonor(donorId);

  @override
  Stream<ImpactMetricsModel> watchMetrics(String donorId) => _firestoreService
      .watchDonorMetrics(donorId)
      .map((m) => m ?? ImpactMetricsModel(id: donorId));

  @override
  Future<void> createBatch(BatchModel batch) =>
      _firestoreService.createBatch(batch);

  @override
  Stream<List<BeneficiaryModel>> getBeneficiaries() =>
      _firestoreService.getBeneficiaries();
}
