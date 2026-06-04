import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class DriverRepositoryImpl implements DriverRepository {
  const DriverRepositoryImpl(this._datasource);

  final DriverRemoteDatasource _datasource;

  @override
  Stream<List<BatchSummary>> getOpenBatches() =>
      _datasource.watchOpenBatches().map(
        (models) => models.map(_toSummary).whereType<BatchSummary>().toList(),
      );

  @override
  Stream<BatchSummary?> getActiveBatch(String driverId) => _datasource
      .watchActiveBatch(driverId)
      .map((m) => m != null ? _toSummary(m) : null);

  @override
  Future<void> claimBatch(String batchId, String driverId) =>
      _datasource.claimBatch(batchId, driverId);

  @override
  Future<void> confirmPickup(String batchId, String photoUrl) =>
      _datasource.confirmPickup(batchId, photoUrl);

  @override
  Future<void> confirmDelivery(String batchId, String? notes) =>
      _datasource.confirmDelivery(batchId, notes);

  @override
  Future<void> upsertLocation(String driverId, double lat, double lng) =>
      _datasource.upsertLocation(driverId, lat, lng);

  @override
  Future<void> deleteLocation(String driverId) =>
      _datasource.deleteLocation(driverId);

  @override
  Stream<int> watchPoints(String uid) => _datasource.watchPoints(uid);

  BatchSummary _toSummary(BatchModel m) => BatchSummary(
    id: m.id,
    donorName: m.donorName ?? 'Donor',
    pickupAddress: m.pickupAddress,
    beneficiaryAddress: m.beneficiaryAddress ?? '',
    beneficiaryName: m.beneficiaryName ?? '',
    totalPortions: m.items.length,
    lat: m.pickupLat != 0.0 ? m.pickupLat : 13.7563,
    lng: m.pickupLng != 0.0 ? m.pickupLng : 100.5018,
    foodCategory: m.items.isNotEmpty ? m.items.first.category : 'local_dining',
    pickupWindowStart: m.pickupWindowStart,
    pickupWindowEnd: m.pickupWindowEnd,
    specialInstructions: m.specialInstructions,
    donorContact: m.donorContact,
    items: m.items,
  );
}
