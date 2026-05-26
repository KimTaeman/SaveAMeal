import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saveameal/core/constants/firestore_constants.dart';
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
  }) => _db.collection(FirestoreConstants.batches).doc(batchId).update({
    'status': status.name,
    // ignore: use_null_aware_elements
    if (driverId != null) 'driverId': driverId,
    // ignore: use_null_aware_elements
    if (beneficiaryId != null) 'beneficiaryId': beneficiaryId,
    'updatedAt': DateTime.now().toIso8601String(),
  });

  // ── Intake / beneficiary-status methods ────────────────────────────────────

  Stream<List<BatchModel>> watchActiveDeliveriesForBeneficiary(
    String beneficiaryId,
  ) => _db
      .collection(FirestoreConstants.batches)
      .where('beneficiaryId', isEqualTo: beneficiaryId)
      .where('status', whereIn: ['open', 'claimed', 'pickedUp'])
      .snapshots()
      .map(
        (qs) => qs.docs
            .map((d) => BatchModel.fromJson({...d.data(), 'id': d.id}))
            .toList(),
      );

  // Combines two live Firestore queries: all open (pending) batches system-wide
  // plus this volunteer's own claimed/pickedUp batches. A StreamController is
  // used because Firestore does not support cross-field OR queries natively and
  // rxdart is not a project dependency.
  Stream<List<BatchModel>> watchVolunteerQueue(String volunteerId) {
    var pendingBatches = <BatchModel>[];
    var myBatches = <BatchModel>[];
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? pendingSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? dispatchedSub;
    late StreamController<List<BatchModel>> controller;

    void emit() => controller.add([...pendingBatches, ...myBatches]);

    controller = StreamController<List<BatchModel>>(
      onListen: () {
        pendingSub = _db
            .collection(FirestoreConstants.batches)
            .where('status', isEqualTo: 'open')
            .snapshots()
            .listen((qs) {
              pendingBatches = qs.docs
                  .map((d) => BatchModel.fromJson({...d.data(), 'id': d.id}))
                  .toList();
              emit();
            });

        dispatchedSub = _db
            .collection(FirestoreConstants.batches)
            .where('driverId', isEqualTo: volunteerId)
            .where('status', whereIn: ['claimed', 'pickedUp'])
            .snapshots()
            .listen((qs) {
              myBatches = qs.docs
                  .map((d) => BatchModel.fromJson({...d.data(), 'id': d.id}))
                  .toList();
              emit();
            });
      },
      onCancel: () {
        pendingSub?.cancel();
        dispatchedSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> acceptJob({
    required String batchId,
    required String volunteerId,
    required String volunteerName,
  }) => _db.collection(FirestoreConstants.batches).doc(batchId).update({
    'status': BatchStatus.claimed.name,
    'driverId': volunteerId,
    'volunteerName': volunteerName,
    'updatedAt': DateTime.now().toIso8601String(),
  });

  // Transitions the batch to delivered. If the batch is still in claimed state
  // (volunteer accepted but hasn't explicitly marked pickup), it is first moved
  // to pickedUp so the transition satisfies Firestore Security Rules which
  // require pickedUp → delivered.
  Future<void> confirmDelivery({
    required String batchId,
    required String volunteerId,
  }) async {
    final ref = _db.collection(FirestoreConstants.batches).doc(batchId);
    final snap = await ref.get();
    if (!snap.exists || snap.data() == null) {
      throw Exception('Batch not found: $batchId');
    }
    final currentStatus = snap.data()!['status'] as String?;
    if (currentStatus == BatchStatus.claimed.name) {
      await ref.update({
        'status': BatchStatus.pickedUp.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
    await ref.update({
      'status': BatchStatus.delivered.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setIntakeAvailability({
    required String beneficiaryId,
    required String intakeStatus,
  }) => _db
      .collection(FirestoreConstants.beneficiaries)
      .doc(beneficiaryId)
      .update({'intakeStatus': intakeStatus});

  Stream<String> watchIntakeAvailability(String beneficiaryId) => _db
      .collection(FirestoreConstants.beneficiaries)
      .doc(beneficiaryId)
      .snapshots()
      .map((ds) => ds.data()?['intakeStatus'] as String? ?? 'accepting');

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
}
