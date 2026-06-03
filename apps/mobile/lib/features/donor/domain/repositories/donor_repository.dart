import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';

abstract class DonorRepository {
  Stream<List<Batch>> watchActiveBatches(String donorId);
  Stream<DonorMetrics> watchMetrics(String donorId);
  Future<void> createBatch(Batch batch);
  Stream<List<Beneficiary>> getBeneficiaries();
  Stream<List<Batch>> watchAllBatches(String donorId);
  Stream<Batch> watchBatchById(String batchId);
}
