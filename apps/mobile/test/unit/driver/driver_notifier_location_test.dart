import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';

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
    'confirmDelivery calls deleteLocation with the driverId from claimBatch',
    () async {
      final repo = _FakeRepo();
      final container = _makeContainer(repo);
      final notifier = container.read(driverProvider.notifier);

      await notifier.claimBatch('b1', 'd1');
      expect(container.read(driverProvider).step, DriverStep.claimed);

      await notifier.confirmDelivery('b1', null);
      // Let the unawaited deleteLocation future complete.
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
