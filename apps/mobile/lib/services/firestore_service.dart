import 'dart:async';

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

  // Firestore returns native Timestamp objects for server-side timestamps, but
  // the Freezed-generated fromJson expects ISO-8601 strings. This helper
  // converts Timestamps (and recurses into nested maps/lists) before fromJson.
  static Map<String, dynamic> _normalise(Map<String, dynamic> raw) {
    return raw.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      }
      if (value is List) {
        return MapEntry(
          key,
          value
              .map((e) => e is Map<String, dynamic> ? _normalise(e) : e)
              .toList(),
        );
      }
      if (value is Map<String, dynamic>) {
        return MapEntry(key, _normalise(value));
      }
      return MapEntry(key, value);
    });
  }

  Future<void> createUser(UserModel user) async {
    final extra = user.role == UserRole.driver
        ? {
            'mealsSaved': 0,
            'sproutPoints': 0,
            'rank': 0,
            'totalDrivers': 0,
            'rankProgressCurrent': 0,
            'rankProgressTarget': 100,
            'currentRankName': 'Bronze',
            'nextRankName': 'Silver',
          }
        : <String, dynamic>{};
    await _db.collection(FirestoreConstants.users).doc(user.uid).set({
      ...user.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      ...extra,
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> fields) => _db
      .collection(FirestoreConstants.users)
      .doc(uid)
      .set(fields, SetOptions(merge: true));

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
            .map(
              (d) => BatchModel.fromJson(_normalise({...d.data(), 'id': d.id})),
            )
            .toList(),
      );

  Stream<BatchModel?> watchBatch(String batchId) => _db
      .collection(FirestoreConstants.batches)
      .doc(batchId)
      .snapshots()
      .map(
        (ds) => ds.exists && ds.data() != null
            ? BatchModel.fromJson(_normalise({...ds.data()!, 'id': ds.id}))
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
            .map(
              (d) => BatchModel.fromJson(_normalise({...d.data(), 'id': d.id})),
            )
            .toList(),
      );

  /// Returns the last 3 completed deliveries for a beneficiary, sorted by
  /// deliveredAt descending (client-side, to avoid a composite Firestore index).
  Stream<List<BatchModel>> watchRecentDeliveriesForBeneficiary(
    String beneficiaryId,
  ) => _db
      .collection(FirestoreConstants.batches)
      .where('beneficiaryId', isEqualTo: beneficiaryId)
      .where('status', whereIn: ['delivered', 'closed'])
      .limit(20)
      .snapshots()
      .map((qs) {
        final docs =
            qs.docs
                .map(
                  (d) => BatchModel.fromJson(
                    _normalise({...d.data(), 'id': d.id}),
                  ),
                )
                .toList()
              ..sort((a, b) {
                final ta = a.deliveredAt ?? a.updatedAt ?? DateTime(0);
                final tb = b.deliveredAt ?? b.updatedAt ?? DateTime(0);
                return tb.compareTo(ta);
              });
        return docs.take(3).toList();
      });

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
                  .map(
                    (d) => BatchModel.fromJson(
                      _normalise({...d.data(), 'id': d.id}),
                    ),
                  )
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
                  .map(
                    (d) => BatchModel.fromJson(
                      _normalise({...d.data(), 'id': d.id}),
                    ),
                  )
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
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> setIntakeAvailability({
    required String beneficiaryId,
    required String intakeStatus,
  }) => _db.collection(FirestoreConstants.beneficiaries).doc(beneficiaryId).set(
    {'intakeStatus': intakeStatus},
    SetOptions(merge: true),
  );

  Stream<String> watchIntakeAvailability(String beneficiaryId) => _db
      .collection(FirestoreConstants.beneficiaries)
      .doc(beneficiaryId)
      .snapshots()
      .map((ds) => ds.data()?['intakeStatus'] as String? ?? 'accepting');

  Stream<BatchModel?> watchActiveBatchForDriver(String driverId) => _db
      .collection(FirestoreConstants.batches)
      .where('driverId', isEqualTo: driverId)
      .snapshots()
      // Status filter is applied client-side to avoid a composite Firestore index
      // (driverId + status). A driver will rarely have more than one active batch.
      .map((qs) {
        final active = qs.docs
            .map(
              (d) => BatchModel.fromJson(_normalise({...d.data(), 'id': d.id})),
            )
            .where(
              (m) =>
                  m.status == BatchStatus.claimed ||
                  m.status == BatchStatus.pickedUp,
            )
            .toList();
        return active.isEmpty ? null : active.first;
      });

  Future<void> claimBatch(String batchId, String driverId) async {
    final batchRef = _db.collection(FirestoreConstants.batches).doc(batchId);

    // Pre-fetch an available beneficiary outside the transaction — Firestore
    // only supports doc reads (not collection queries) inside transactions.
    // The value is only written if the batch has no beneficiaryId yet.
    final autoId = await findAvailableBeneficiaryId();

    await _db.runTransaction((tx) async {
      final snap = await tx.get(batchRef);
      if (!snap.exists || snap.data() == null) {
        throw BatchNotFoundException(batchId);
      }
      if (snap.data()!['status'] != 'open') {
        throw const BatchAlreadyClaimedException();
      }

      final update = <String, dynamic>{
        'status': 'claimed',
        'driverId': driverId,
        'claimedAt': FieldValue.serverTimestamp(),
      };

      if (snap.data()!['beneficiaryId'] == null && autoId != null) {
        update['beneficiaryId'] = autoId;
      }

      tx.update(batchRef, update);
    });
  }

  /// Returns the ID of the first beneficiary currently accepting food,
  /// or null if none are available.
  Future<String?> findAvailableBeneficiaryId() async {
    final qs = await _db
        .collection(FirestoreConstants.beneficiaries)
        .where('intakeStatus', isEqualTo: 'accepting')
        .limit(1)
        .get();
    return qs.docs.isEmpty ? null : qs.docs.first.id;
  }

  Future<void> confirmPickup(String batchId, String pickupPhotoUrl) =>
      _db.collection(FirestoreConstants.batches).doc(batchId).update({
        'status': 'pickedUp',
        'pickedUpAt': FieldValue.serverTimestamp(),
        'pickupPhotoUrl': pickupPhotoUrl,
      });

  // Handles claimed → pickedUp → delivered transition. If the batch is still
  // in claimed state (volunteer accepted but never explicitly marked pickup),
  // it is promoted to pickedUp first to satisfy Firestore Security Rules.
  Future<void> confirmDelivery(String batchId, String? notes) async {
    final ref = _db.collection(FirestoreConstants.batches).doc(batchId);
    final snap = await ref.get();
    if (!snap.exists || snap.data() == null) {
      throw Exception('Batch not found: $batchId');
    }
    if (snap.data()!['status'] == BatchStatus.claimed.name) {
      await ref.update({
        'status': BatchStatus.pickedUp.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    final data = <String, dynamic>{
      'status': 'delivered',
      'deliveredAt': FieldValue.serverTimestamp(),
    };
    if (notes != null && notes.isNotEmpty) data['deliveryNotes'] = notes;
    await ref.update(data);

    final driverId = snap.data()!['driverId'] as String?;
    if (driverId != null && driverId.isNotEmpty) {
      final items = (snap.data()!['items'] as List?) ?? [];
      final meals = items.isEmpty ? 10 : items.length * 10;
      await _db.collection(FirestoreConstants.users).doc(driverId).update({
        'totalPickups': FieldValue.increment(1),
        'mealsSaved': FieldValue.increment(meals),
        'sproutPoints': FieldValue.increment(meals),
        'points': FieldValue.increment(meals),
        'rankProgressCurrent': FieldValue.increment(meals),
      });
    }
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

  // Aggregates directly from the donor's batches — avoids the dependency on the
  // onDeliveryComplete Cloud Function which pre-computes impactMetrics.
  // Uses async* so that Firestore permission errors and bad-cast errors in the
  // aggregation loop are caught and turned into a default (zero) emission rather
  // than a stream error that trips the dashboard's offline banner.
  Stream<ImpactMetricsModel?> watchDonorMetrics(String donorId) async* {
    try {
      await for (final qs
          in _db
              .collection(FirestoreConstants.batches)
              .where('donorId', isEqualTo: donorId)
              .snapshots()) {
        try {
          double totalKg = 0;
          int totalDeliveries = 0;
          for (final doc in qs.docs) {
            final data = doc.data();
            if (data['status'] == 'cancelled') continue;
            for (final raw in (data['items'] as List<dynamic>? ?? [])) {
              final item = raw as Map<String, dynamic>;
              final kg = item['weightKg'];
              if (kg != null) totalKg += (kg as num).toDouble();
            }
            final status = data['status'] as String?;
            if (status == 'delivered' || status == 'closed') totalDeliveries++;
          }
          yield ImpactMetricsModel(
            id: donorId,
            totalKg: totalKg,
            totalMeals: (totalKg * 2.5).round(),
            totalCO2e: totalKg * 2.5,
            totalDeliveries: totalDeliveries,
          );
        } catch (_) {
          yield ImpactMetricsModel(id: donorId);
        }
      }
    } catch (_) {
      // Firestore stream error (permission denied, network) — emit default once.
      yield ImpactMetricsModel(id: donorId);
    }
  }

  // Queries the beneficiaries collection directly, filtered to those currently
  // accepting food. All profile fields (name, address, lat/lng, etc.) are read
  // from the beneficiaries doc. Falls back to orgName, then document ID if
  // the name field is absent.
  Stream<List<BeneficiaryModel>> getBeneficiaries() => _db
      .collection(FirestoreConstants.beneficiaries)
      .where('intakeStatus', isEqualTo: 'accepting')
      .snapshots()
      .map(
        (qs) => qs.docs.map((d) {
          final data = d.data();
          final name = data['name'] as String?;
          final orgName = data['orgName'] as String?;
          final resolvedName = (name != null && name.isNotEmpty)
              ? name
              : (orgName != null && orgName.isNotEmpty)
              ? orgName
              : d.id;
          return BeneficiaryModel(
            id: d.id,
            name: resolvedName,
            address: data['address'] as String?,
            lat: (data['lat'] as num?)?.toDouble(),
            lng: (data['lng'] as num?)?.toDouble(),
            orgType: data['orgType'] as String?,
            contactEmail: data['contactEmail'] as String?,
            missionStatement: data['missionStatement'] as String?,
          );
        }).toList(),
      );

  // No orderBy here — avoids composite index requirement.
  // The repository sorts client-side by createdAt descending.
  Stream<List<BatchModel>> watchActiveBatchesForDonor(String donorId) => _db
      .collection(FirestoreConstants.batches)
      .where('donorId', isEqualTo: donorId)
      .snapshots()
      .map(
        (qs) => qs.docs
            .map(
              (d) => BatchModel.fromJson(_normalise({...d.data(), 'id': d.id})),
            )
            .where((m) => m.status != BatchStatus.closed)
            .toList(),
      );

  /// All batches for this donor regardless of status. Sorted client-side.
  Stream<List<BatchModel>> watchAllBatchesForDonor(String donorId) => _db
      .collection(FirestoreConstants.batches)
      .where('donorId', isEqualTo: donorId)
      .snapshots()
      .map(
        (qs) => qs.docs
            .map(
              (d) => BatchModel.fromJson(_normalise({...d.data(), 'id': d.id})),
            )
            .toList(),
      );

  Stream<int> watchUserPoints(String uid) =>
      _db.collection(FirestoreConstants.users).doc(uid).snapshots().map((ds) {
        if (!ds.exists || ds.data() == null) return 0;
        return (ds.data()!['points'] as int?) ?? 0;
      });

  Future<void> updateFcmToken(String uid, String token) => _db
      .collection(FirestoreConstants.users)
      .doc(uid)
      .update({'fcmToken': token});

  Future<void> deleteDriverLocation(String driverId) =>
      _db.collection(FirestoreConstants.driverLocations).doc(driverId).delete();

  Stream<UserModel?> watchUser(String uid) => _db
      .collection(FirestoreConstants.users)
      .doc(uid)
      .snapshots()
      .map(
        (ds) => ds.exists && ds.data() != null
            ? UserModel.fromJson(ds.data()!)
            : null,
      );

  Stream<BeneficiaryModel?> watchBeneficiaryDoc(String uid) => _db
      .collection(FirestoreConstants.beneficiaries)
      .doc(uid)
      .snapshots()
      .map(
        (ds) => ds.exists && ds.data() != null
            ? BeneficiaryModel.fromJson({...ds.data()!, 'id': ds.id})
            : null,
      );

  Future<BeneficiaryModel?> getBeneficiary(String beneficiaryId) async {
    final doc = await _db
        .collection(FirestoreConstants.beneficiaries)
        .doc(beneficiaryId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return BeneficiaryModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  /// Fetches a single page of delivered/closed batches for [beneficiaryId].
  /// Uses cursor-based pagination via startAfterDocument. Results are sorted
  /// by deliveredAt descending client-side (in FirestoreIntakeRepository) to
  /// avoid requiring a composite Firestore index on (beneficiaryId, status,
  /// deliveredAt) — the same no-orderBy pattern used by
  /// watchRecentDeliveriesForBeneficiary.
  Future<(List<BatchModel>, Object? nextCursor)> fetchDeliveryHistoryPage({
    required String beneficiaryId,
    required int pageSize,
    Object? cursor,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection(FirestoreConstants.batches)
        .where('beneficiaryId', isEqualTo: beneficiaryId)
        .where('status', whereIn: ['delivered', 'closed'])
        .limit(pageSize);

    if (cursor != null) {
      if (cursor is! DocumentSnapshot) {
        throw ArgumentError(
          'cursor must be a DocumentSnapshot, got ${cursor.runtimeType}',
        );
      }
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();
    final nextCursor = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final models = snapshot.docs
        .map(
          (doc) =>
              BatchModel.fromJson(_normalise({...doc.data(), 'id': doc.id})),
        )
        .toList();
    return (models, nextCursor);
  }

  Future<Map<String, dynamic>?> getBeneficiaryMap(String beneficiaryId) async {
    final doc = await _db
        .collection(FirestoreConstants.beneficiaries)
        .doc(beneficiaryId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return {...doc.data()!, 'id': doc.id};
  }

  Future<void> updateBeneficiary(
    String beneficiaryId,
    Map<String, dynamic> data,
  ) => _db
      .collection(FirestoreConstants.beneficiaries)
      .doc(beneficiaryId)
      .set(data, SetOptions(merge: true));

  Future<void> confirmReceipt({
    required String batchId,
    int? rating,
    String? feedback,
  }) async {
    final update = <String, dynamic>{
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
      'rating': ?rating,
      if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
    };
    await _db
        .collection(FirestoreConstants.batches)
        .doc(batchId)
        .update(update);
  }

  FirebaseFirestore get db => _db;
}
