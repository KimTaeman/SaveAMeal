import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';

class _FakeRepo implements DriverRepository {
  String? lastDeletedLocationDriverId;

  @override
  Future<void> claimBatch(String batchId, String driverId) async {}

  @override
  Future<void> confirmPickup(String batchId, String photoUrl) async {}

  @override
  Future<void> confirmDelivery(String batchId, String? notes) async {}

  @override
  Stream<List<BatchSummary>> getOpenBatches() => const Stream.empty();

  @override
  Stream<BatchSummary?> getActiveBatch(String driverId) => const Stream.empty();

  @override
  Future<void> upsertLocation(String driverId, double lat, double lng) async {}

  @override
  Future<void> deleteLocation(String driverId) async {
    lastDeletedLocationDriverId = driverId;
  }

  @override
  Future<void> updateBatchEta(String batchId, int eta) async {}

  @override
  Stream<int> watchPoints(String uid) => const Stream.empty();
}

class _FakeDatasource implements DriverRemoteDatasource {
  @override
  Future<String> uploadPickupPhoto(String batchId, XFile photo) async =>
      'https://fake.url/photo.jpg';

  @override
  Stream<List<BatchModel>> watchOpenBatches() => const Stream.empty();

  @override
  Stream<BatchModel?> watchActiveBatch(String driverId) => const Stream.empty();

  @override
  Future<void> claimBatch(String batchId, String driverId) async {}

  @override
  Future<void> confirmPickup(String batchId, String pickupPhotoUrl) async {}

  @override
  Future<void> confirmDelivery(String batchId, String? notes) async {}

  @override
  Future<void> upsertLocation(String driverId, double lat, double lng) async {}

  @override
  Future<void> deleteLocation(String driverId) async {}

  @override
  Future<void> updateBatchEta(String batchId, int eta) async {}

  @override
  Stream<int> watchPoints(String uid) => const Stream.empty();
}

ProviderContainer _makeContainer(_FakeRepo repo) => ProviderContainer(
  overrides: [
    driverRepositoryProvider.overrideWithValue(repo),
    driverRemoteDatasourceProvider.overrideWithValue(_FakeDatasource()),
  ],
);

void main() {
  test(
    'confirmDelivery calls deleteLocation after tracking was started',
    () async {
      final repo = _FakeRepo();
      final container = _makeContainer(repo);
      final notifier = container.read(driverProvider.notifier);

      // In tests, Geolocator platform is unavailable so _startTracking returns
      // early without setting _activeDriverId. Simulate a successful tracking
      // start by setting it directly.
      await notifier.claimBatch('b1', 'd1');
      notifier.setActiveDriverIdForTest('d1');

      await notifier.confirmDelivery('b1', null);
      await Future<void>.delayed(Duration.zero);

      expect(repo.lastDeletedLocationDriverId, 'd1');
    },
  );

  test(
    'stopTracking without a prior startTracking is a no-op (no deleteLocation called)',
    () async {
      final repo = _FakeRepo();
      final container = _makeContainer(repo);
      final notifier = container.read(driverProvider.notifier);

      // Confirm delivery without ever claiming — _activeDriverId is null
      await notifier.confirmDelivery('b1', null);
      await Future<void>.delayed(Duration.zero);

      expect(repo.lastDeletedLocationDriverId, isNull);
    },
  );
}
