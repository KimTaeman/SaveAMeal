import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saveameal/core/constants/firestore_constants.dart';
import 'package:saveameal/core/exceptions/batch_exceptions.dart';
import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/core/models/beneficiary_model.dart';
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

  Stream<List<BatchModel>> watchOpenBatches() => _db
      .collection(FirestoreConstants.batches)
      .where('status', isEqualTo: 'open')
      .snapshots()
      .map(
        (qs) => qs.docs
            .map((d) => BatchModel.fromJson({...d.data(), 'id': d.id}))
            .toList(),
      );

  Stream<BatchModel?> watchBatch(String batchId) => _db
      .collection(FirestoreConstants.batches)
      .doc(batchId)
      .snapshots()
      .map(
        (ds) => ds.exists && ds.data() != null
            ? BatchModel.fromJson({...ds.data()!, 'id': ds.id})
            : null,
      );

  Future<void> updateBatchStatus(
    String batchId,
    BatchStatus status, {
    String? driverId,
    String? beneficiaryId,
  }) async {
    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (driverId != null) data['driverId'] = driverId;
    if (beneficiaryId != null) data['beneficiaryId'] = beneficiaryId;
    await _db.collection(FirestoreConstants.batches).doc(batchId).update(data);
  }

  Stream<BatchModel?> watchActiveBatchForDriver(String driverId) => _db
      .collection(FirestoreConstants.batches)
      .where('driverId', isEqualTo: driverId)
      .snapshots()
      // Status filter is applied client-side to avoid a composite Firestore index
      // (driverId + status). A driver will rarely have more than one active batch.
      .map((qs) {
        final active = qs.docs
            .map((d) => BatchModel.fromJson({...d.data(), 'id': d.id}))
            .where(
              (m) =>
                  m.status == BatchStatus.claimed ||
                  m.status == BatchStatus.pickedUp,
            )
            .toList();
        return active.isEmpty ? null : active.first;
      });

  Future<void> claimBatch(String batchId, String driverId) async {
    final ref = _db.collection(FirestoreConstants.batches).doc(batchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data() == null) {
        throw BatchNotFoundException(batchId);
      }
      if (snap.data()!['status'] != 'open') {
        throw const BatchAlreadyClaimedException();
      }
      tx.update(ref, {
        'status': 'claimed',
        'driverId': driverId,
        'claimedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> confirmPickup(String batchId, String pickupPhotoUrl) =>
      _db.collection(FirestoreConstants.batches).doc(batchId).update({
        'status': 'pickedUp',
        'pickedUpAt': FieldValue.serverTimestamp(),
        'pickupPhotoUrl': pickupPhotoUrl,
      });

  Future<void> confirmDelivery(String batchId, String? notes) async {
    final data = <String, dynamic>{
      'status': 'delivered',
      'deliveredAt': FieldValue.serverTimestamp(),
    };
    if (notes != null && notes.isNotEmpty) data['deliveryNotes'] = notes;
    await _db.collection(FirestoreConstants.batches).doc(batchId).update(data);
  }

  Future<void> upsertDriverLocation(DriverLocationModel loc) => _db
      .collection(FirestoreConstants.driverLocations)
      .doc(loc.driverId)
      .set(loc.toJson());

  Stream<DriverLocationModel?> watchDriverLocation(String driverId) => _db
      .collection(FirestoreConstants.driverLocations)
      .doc(driverId)
      .snapshots()
      .map(
        (ds) => ds.exists && ds.data() != null
            ? DriverLocationModel.fromJson(ds.data()!)
            : null,
      );

  Stream<ImpactMetricsModel?> watchDonorMetrics(String donorId) => _db
      .collection(FirestoreConstants.impactMetrics)
      .doc(donorId)
      .snapshots()
      .map(
        (ds) => ds.exists && ds.data() != null
            ? ImpactMetricsModel.fromJson({...ds.data()!, 'id': donorId})
            : ImpactMetricsModel(id: donorId),
      );

  Stream<List<BeneficiaryModel>> getBeneficiaries() => _db
      .collection(FirestoreConstants.beneficiaries)
      .snapshots()
      .map(
        (qs) => qs.docs
            .map((d) => BeneficiaryModel.fromJson({...d.data(), 'id': d.id}))
            .toList(),
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

  Stream<int> watchUserPoints(String uid) =>
      _db.collection(FirestoreConstants.users).doc(uid).snapshots().map((ds) {
        if (!ds.exists || ds.data() == null) return 0;
        return (ds.data()!['points'] as int?) ?? 0;
      });
}
