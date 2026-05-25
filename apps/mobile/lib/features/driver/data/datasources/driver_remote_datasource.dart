import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/core/models/driver_location_model.dart';
import 'package:saveameal/services/firestore_service.dart';
import 'package:saveameal/services/storage_service.dart';

abstract class DriverRemoteDatasource {
  Stream<List<BatchModel>> watchOpenBatches();
  Stream<BatchModel?> watchActiveBatch(String driverId);
  Future<void> claimBatch(String batchId, String driverId);
  Future<void> confirmPickup(String batchId, String pickupPhotoUrl);
  Future<void> confirmDelivery(String batchId, String? notes);
  Future<void> upsertLocation(String driverId, double lat, double lng);
  Future<String> uploadPickupPhoto(String batchId, String localPath);
  Stream<int> watchPoints(String uid);
}

class DriverRemoteDatasourceImpl implements DriverRemoteDatasource {
  const DriverRemoteDatasourceImpl(this._firestore, this._storage);

  final FirestoreService _firestore;
  final StorageService _storage;

  @override
  Stream<List<BatchModel>> watchOpenBatches() => _firestore.watchOpenBatches();

  @override
  Stream<BatchModel?> watchActiveBatch(String driverId) =>
      _firestore.watchActiveBatchForDriver(driverId);

  @override
  Future<void> claimBatch(String batchId, String driverId) =>
      _firestore.claimBatch(batchId, driverId);

  @override
  Future<void> confirmPickup(String batchId, String pickupPhotoUrl) =>
      _firestore.confirmPickup(batchId, pickupPhotoUrl);

  @override
  Future<void> confirmDelivery(String batchId, String? notes) =>
      _firestore.confirmDelivery(batchId, notes);

  @override
  Future<void> upsertLocation(String driverId, double lat, double lng) =>
      _firestore.upsertDriverLocation(
        DriverLocationModel(driverId: driverId, lat: lat, lng: lng),
      );

  @override
  Future<String> uploadPickupPhoto(String batchId, String localPath) =>
      _storage.uploadPickupPhoto(batchId, localPath);

  @override
  Stream<int> watchPoints(String uid) => _firestore.watchUserPoints(uid);
}
