// Pure Dart interface — no Flutter or backend imports.
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';

abstract class DonorRepository {
  /// Emits the donor's active batches (status != closed) in real time.
  /// First emission comes from Hive cache; subsequent emissions from Firestore.
  Stream<List<Batch>> watchActiveBatches(String donorId);

  /// Emits the donor's cumulative impact metrics in real time.
  /// First emission comes from Hive cache (or DonorMetrics.empty if cold).
  Stream<DonorMetrics> watchMetrics(String donorId);

  /// Writes a new batch document to Firestore.
  Future<void> createBatch(Batch batch);
}
