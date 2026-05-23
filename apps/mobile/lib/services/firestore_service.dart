import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saveameal/core/constants/firestore_constants.dart';
import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/core/models/driver_location_model.dart';
import 'package:saveameal/core/models/impact_metrics_model.dart';
import 'package:saveameal/core/models/user_model.dart';

class FirestoreService {
  FirestoreService(this._db);

  final FirebaseFirestore _db;

  Future<void> createUser(UserModel user) =>
      _db.collection(FirestoreConstants.users).doc(user.uid).set(user.toJson());

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(FirestoreConstants.users).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson(doc.data()!);
  }

  Future<void> createBatch(BatchModel batch) => _db
      .collection(FirestoreConstants.batches)
      .doc(batch.id)
      .set(batch.toJson());

  Stream<List<BatchModel>> watchOpenBatches() =>
      throw UnimplementedError('watchOpenBatches not implemented');

  Stream<BatchModel?> watchBatch(String batchId) =>
      throw UnimplementedError('watchBatch not implemented');

  Future<void> updateBatchStatus(
    String batchId,
    BatchStatus status, {
    String? driverId,
    String? beneficiaryId,
  }) => throw UnimplementedError('updateBatchStatus not implemented');

  Future<void> upsertDriverLocation(DriverLocationModel loc) =>
      throw UnimplementedError('upsertDriverLocation not implemented');

  Stream<DriverLocationModel?> watchDriverLocation(String driverId) =>
      throw UnimplementedError('watchDriverLocation not implemented');

  Stream<ImpactMetricsModel?> watchDonorMetrics(String donorId) => _db
      .collection(FirestoreConstants.impactMetrics)
      .doc(donorId)
      .snapshots()
      .map(
        (ds) => ds.exists && ds.data() != null
            ? ImpactMetricsModel.fromJson({...ds.data()!, 'id': donorId})
            : ImpactMetricsModel(id: donorId),
      );

  // No orderBy here — avoids composite index requirement.
  // The repository sorts client-side by createdAt descending.
  Stream<List<BatchModel>> watchActiveBatchesForDonor(String donorId) => _db
      .collection(FirestoreConstants.batches)
      .where('donorId', isEqualTo: donorId)
      .snapshots()
      .map(
        (qs) => qs.docs
            .map((d) => BatchModel.fromJson({...d.data(), 'id': d.id}))
            .where((m) => m.status != BatchStatus.closed)
            .toList(),
      );
}
