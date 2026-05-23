import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saveameal/core/constants/firestore_constants.dart';
import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/core/models/driver_location_model.dart';
import 'package:saveameal/core/models/impact_metrics_model.dart';
import 'package:saveameal/core/models/user_model.dart';

class FirestoreService {
  FirestoreService(this._db);

  final FirebaseFirestore _db;

  Future<void> createUser(UserModel user) => _db
      .collection(FirestoreConstants.users)
      .doc(user.uid)
      .set(user.toJson());

  Future<UserModel?> getUser(String uid) async {
    final doc =
        await _db.collection(FirestoreConstants.users).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson(doc.data()!);
  }

  Future<void> createBatch(BatchModel batch) =>
      throw UnimplementedError('createBatch not implemented');

  Stream<List<BatchModel>> watchOpenBatches() =>
      throw UnimplementedError('watchOpenBatches not implemented');

  Stream<BatchModel?> watchBatch(String batchId) =>
      throw UnimplementedError('watchBatch not implemented');

  Future<void> updateBatchStatus(
    String batchId,
    BatchStatus status, {
    String? driverId,
    String? beneficiaryId,
  }) =>
      throw UnimplementedError('updateBatchStatus not implemented');

  Future<void> upsertDriverLocation(DriverLocationModel loc) =>
      throw UnimplementedError('upsertDriverLocation not implemented');

  Stream<DriverLocationModel?> watchDriverLocation(String driverId) =>
      throw UnimplementedError('watchDriverLocation not implemented');

  Stream<ImpactMetricsModel?> watchDonorMetrics(String donorId) =>
      throw UnimplementedError('watchDonorMetrics not implemented');
}
