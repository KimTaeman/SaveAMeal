// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saveameal/core/constants/firestore_constants.dart';
import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/core/models/driver_location_model.dart';
import 'package:saveameal/core/models/impact_metrics_model.dart';
import 'package:saveameal/core/models/user_model.dart';

/// Wraps Cloud Firestore. All methods throw [UnimplementedError] until wired up.
class FirestoreService {
  // TODO: inject FirebaseFirestore instance and wire up all methods
  // FirestoreConstants is referenced by collection name strings at implementation time:
  // e.g. FirestoreConstants.users, FirestoreConstants.batches, etc.

  /// Writes a [UserModel] document to the `users` collection.
  Future<void> createUser(UserModel user) =>
      // TODO: implement
      throw UnimplementedError('createUser not implemented');

  /// Fetches a single [UserModel] by [uid], or null if not found.
  Future<UserModel?> getUser(String uid) =>
      // TODO: implement
      throw UnimplementedError('getUser not implemented');

  /// Writes a [BatchModel] document to the `batches` collection.
  Future<void> createBatch(BatchModel batch) =>
      // TODO: implement
      throw UnimplementedError('createBatch not implemented');

  /// Streams all batches whose status is [BatchStatus.open].
  Stream<List<BatchModel>> watchOpenBatches() =>
      // TODO: implement
      throw UnimplementedError('watchOpenBatches not implemented');

  /// Streams a single batch document, or null if it does not exist.
  Stream<BatchModel?> watchBatch(String batchId) =>
      // TODO: implement
      throw UnimplementedError('watchBatch not implemented');

  /// Updates the status of a batch, optionally assigning a driver or beneficiary.
  Future<void> updateBatchStatus(
    String batchId,
    BatchStatus status, {
    String? driverId,
    String? beneficiaryId,
  }) =>
      // TODO: implement
      throw UnimplementedError('updateBatchStatus not implemented');

  /// Creates or overwrites a driver location document.
  Future<void> upsertDriverLocation(DriverLocationModel loc) =>
      // TODO: implement
      throw UnimplementedError('upsertDriverLocation not implemented');

  /// Streams a single driver's location, or null if not found.
  Stream<DriverLocationModel?> watchDriverLocation(String driverId) =>
      // TODO: implement
      throw UnimplementedError('watchDriverLocation not implemented');

  /// Streams impact metrics for a specific donor.
  Stream<ImpactMetricsModel?> watchDonorMetrics(String donorId) =>
      // TODO: implement
      throw UnimplementedError('watchDonorMetrics not implemented');
}
