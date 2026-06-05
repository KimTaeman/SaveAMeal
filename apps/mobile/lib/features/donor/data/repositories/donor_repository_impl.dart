import 'package:hive_flutter/hive_flutter.dart';
import 'package:saveameal/core/models/batch_item_model.dart';
import 'package:saveameal/core/models/batch_model.dart' as bm;
import 'package:saveameal/core/models/beneficiary_model.dart';
import 'package:saveameal/core/models/impact_metrics_model.dart';
import 'package:saveameal/features/donor/data/datasources/donor_remote_datasource.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart' as domain;
import 'package:saveameal/features/donor/domain/entities/batch_item.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';

class DonorRepositoryImpl implements DonorRepository {
  const DonorRepositoryImpl(this._datasource);

  final DonorRemoteDatasource _datasource;

  static const _batchesBox = 'donor_batches';
  static const _metricsBox = 'donor_metrics';

  @override
  Stream<List<domain.Batch>> watchActiveBatches(String donorId) async* {
    final box = Hive.box(_batchesBox);
    final cached = box.get(donorId);
    if (cached != null) {
      yield (cached as List)
          .map(
            (m) => _toBatch(
              bm.BatchModel.fromJson(Map<String, dynamic>.from(m as Map)),
            ),
          )
          .toList();
    } else {
      yield [];
    }
    await for (final models in _datasource.watchActiveBatches(donorId)) {
      final sorted = [...models]
        ..sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
      await box.put(donorId, sorted.map((m) => m.toJson()).toList());
      yield sorted.map(_toBatch).toList();
    }
  }

  @override
  Stream<DonorMetrics> watchMetrics(String donorId) async* {
    final box = Hive.box(_metricsBox);
    final cached = box.get(donorId);
    if (cached != null) {
      yield _toMetrics(
        ImpactMetricsModel.fromJson(Map<String, dynamic>.from(cached as Map)),
      );
    } else {
      yield DonorMetrics.empty;
    }
    await for (final model in _datasource.watchMetrics(donorId)) {
      await box.put(donorId, model.toJson());
      yield _toMetrics(model);
    }
  }

  @override
  Future<void> createBatch(domain.Batch batch) =>
      _datasource.createBatch(_fromBatch(batch));

  @override
  Stream<List<Beneficiary>> getBeneficiaries() => _datasource
      .getBeneficiaries()
      .map((models) => models.map(_toBeneficiary).toList());

  @override
  Stream<List<domain.Batch>> watchAllBatches(String donorId) => _datasource
      .watchAllBatches(donorId)
      .map((models) => models.map(_toBatch).toList());

  @override
  Stream<domain.Batch> watchBatchById(String batchId) =>
      _datasource.watchBatchById(batchId).map(_toBatch);

  // ── Mappers ────────────────────────────────────────────────────────────────

  domain.Batch _toBatch(bm.BatchModel m) => domain.Batch(
    id: m.id,
    donorId: m.donorId,
    items: m.items.map(_toBatchItem).toList(),
    pickupAddress: m.pickupAddress,
    status: m.status,
    driverId: m.driverId,
    volunteerName: m.volunteerName,
    beneficiaryId: m.beneficiaryId,
    beneficiaryName: m.beneficiaryName,
    beneficiaryAddress: m.beneficiaryAddress,
    donorName: m.donorName,
    pickupLat: m.pickupLat,
    pickupLng: m.pickupLng,
    pickupWindowStart: m.pickupWindowStart,
    pickupWindowEnd: m.pickupWindowEnd,
    specialInstructions: m.specialInstructions,
    photoUrl: m.photoUrl,
    pickupPhotoUrl: m.pickupPhotoUrl,
    qrCode: m.qrCode,
    claimedAt: m.claimedAt,
    pickedUpAt: m.pickedUpAt,
    deliveredAt: m.deliveredAt,
    deliveryNotes: m.deliveryNotes,
    rating: m.rating,
    feedback: m.feedback,
    createdAt: m.createdAt,
    updatedAt: m.updatedAt,
  );

  bm.BatchModel _fromBatch(domain.Batch b) => bm.BatchModel(
    id: b.id,
    donorId: b.donorId,
    items: b.items.map(_fromBatchItem).toList(),
    pickupAddress: b.pickupAddress,
    status: b.status,
    driverId: b.driverId,
    volunteerName: b.volunteerName,
    beneficiaryId: b.beneficiaryId,
    beneficiaryName: b.beneficiaryName,
    beneficiaryAddress: b.beneficiaryAddress,
    donorName: b.donorName,
    pickupLat: b.pickupLat,
    pickupLng: b.pickupLng,
    pickupWindowStart: b.pickupWindowStart,
    pickupWindowEnd: b.pickupWindowEnd,
    specialInstructions: b.specialInstructions,
    photoUrl: b.photoUrl,
    pickupPhotoUrl: b.pickupPhotoUrl,
    qrCode: b.qrCode,
    claimedAt: b.claimedAt,
    pickedUpAt: b.pickedUpAt,
    deliveredAt: b.deliveredAt,
    deliveryNotes: b.deliveryNotes,
    rating: b.rating,
    feedback: b.feedback,
    createdAt: b.createdAt,
    updatedAt: b.updatedAt,
  );

  BatchItem _toBatchItem(BatchItemModel m) => BatchItem(
    name: m.name,
    category: FoodCategory.fromString(m.category),
    weightKg: m.weightKg,
    expiryTime: m.expiryTime,
    photoUrl: m.photoUrl,
  );

  BatchItemModel _fromBatchItem(BatchItem i) => BatchItemModel(
    name: i.name,
    category: i.category.name,
    weightKg: i.weightKg,
    expiryTime: i.expiryTime,
    photoUrl: i.photoUrl,
  );

  DonorMetrics _toMetrics(ImpactMetricsModel m) => DonorMetrics(
    donorId: m.id,
    totalKg: m.totalKg,
    totalMeals: m.totalMeals,
    totalCO2e: m.totalCO2e,
    totalDeliveries: m.totalDeliveries,
  );

  Beneficiary _toBeneficiary(BeneficiaryModel m) =>
      Beneficiary(id: m.id, name: m.name, address: m.address);
}
