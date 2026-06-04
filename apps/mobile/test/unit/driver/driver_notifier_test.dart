import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saveameal/core/exceptions/batch_exceptions.dart';
import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';

class _FakeRepo implements DriverRepository {
  bool claimShouldThrow = false;
  String? lastConfirmedPickup;
  String? lastConfirmedDelivery;
  Stream<BatchSummary?> Function(String driverId)? activeBatchStreamFactory;

  @override
  Future<void> claimBatch(String batchId, String driverId) async {
    if (claimShouldThrow) throw const BatchAlreadyClaimedException();
  }

  @override
  Future<void> confirmPickup(String batchId, String photoUrl) async {
    lastConfirmedPickup = batchId;
  }

  @override
  Future<void> confirmDelivery(String batchId, String? notes) async {
    lastConfirmedDelivery = batchId;
  }

  @override
  Stream<List<BatchSummary>> getOpenBatches() => const Stream.empty();

  @override
  Stream<BatchSummary?> getActiveBatch(String driverId) =>
      activeBatchStreamFactory?.call(driverId) ?? const Stream.empty();

  @override
  Future<void> upsertLocation(String driverId, double lat, double lng) async {}

  String? lastDeletedLocationDriverId;

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
  test('initial state is browsing', () {
    final container = _makeContainer(_FakeRepo());
    expect(container.read(driverProvider).step, DriverStep.browsing);
  });

  test('claimBatch transitions step to claimed', () async {
    final container = _makeContainer(_FakeRepo());
    await container.read(driverProvider.notifier).claimBatch('b1', 'd1');
    expect(container.read(driverProvider).step, DriverStep.claimed);
  });

  test(
    'claimBatch with conflict rethrows BatchAlreadyClaimedException',
    () async {
      final repo = _FakeRepo()..claimShouldThrow = true;
      final container = _makeContainer(repo);
      await expectLater(
        () => container.read(driverProvider.notifier).claimBatch('b1', 'd1'),
        throwsA(isA<BatchAlreadyClaimedException>()),
      );
    },
  );

  test('confirmDelivery transitions step to delivered', () async {
    final container = _makeContainer(_FakeRepo());
    final notifier = container.read(driverProvider.notifier);
    await notifier.claimBatch('b1', 'd1');
    expect(
      container.read(driverProvider).rescuePhase,
      ClaimRescuePhase.enRoutePickup,
    );
    await notifier.confirmPickup('b1', XFile('/fake/path.jpg'));
    expect(
      container.read(driverProvider).rescuePhase,
      ClaimRescuePhase.enRouteBeneficiary,
    );
    await notifier.confirmDelivery('b1', null);
    expect(container.read(driverProvider).step, DriverStep.delivered);
  });

  test(
    'confirmPickup keeps pickup coords and completes without error when beneficiary coords unavailable',
    () async {
      const pickupLat = 13.75, pickupLng = 100.50;
      final batch = BatchSummary(
        id: 'b1',
        donorName: 'Donor',
        pickupAddress: '123 Test St',
        beneficiaryAddress: '456 Ben St',
        beneficiaryName: 'Beneficiary',
        totalPortions: 1,
        lat: pickupLat,
        lng: pickupLng,
        foodCategory: 'grain',
      );

      final repo =
          _FakeRepo(); // activeBatchStreamFactory is null → Stream.empty()
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      // Keep the provider alive across async gaps to prevent auto-dispose.
      container.listen(driverProvider, (prev, next) {});
      final notifier = container.read(driverProvider.notifier);

      notifier.selectBatch(batch);
      await notifier.claimBatch('b1', 'd1');
      await Future<void>.delayed(Duration.zero);

      // No batch emitted → _beneficiaryLat/Lng remain null.
      await notifier.confirmPickup('b1', XFile('/fake/photo.jpg'));

      // ETA destination remains at pickup coords.
      expect(notifier.etaDestinationForTest, (pickupLat, pickupLng));
      // State transition still happens correctly.
      expect(
        container.read(driverProvider).rescuePhase,
        ClaimRescuePhase.enRouteBeneficiary,
      );
    },
  );

  test(
    'confirmPickup switches ETA destination to beneficiary coords when available',
    () async {
      const pickupLat = 13.75, pickupLng = 100.50;
      const benLat = 13.80, benLng = 100.55;
      final batch = BatchSummary(
        id: 'b1',
        donorName: 'Donor',
        pickupAddress: '123 Test St',
        beneficiaryAddress: '456 Ben St',
        beneficiaryName: 'Beneficiary',
        totalPortions: 1,
        lat: pickupLat,
        lng: pickupLng,
        beneficiaryLat: benLat,
        beneficiaryLng: benLng,
        foodCategory: 'grain',
      );

      final controller = StreamController<BatchSummary?>.broadcast();
      addTearDown(controller.close);

      final repo = _FakeRepo()
        ..activeBatchStreamFactory = (_) => controller.stream;
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      // Keep the provider alive across async gaps to prevent auto-dispose.
      container.listen(driverProvider, (prev, next) {});
      final notifier = container.read(driverProvider.notifier);

      notifier.selectBatch(batch);
      await notifier.claimBatch('b1', 'd1');

      // Simulate Firestore emitting the updated batch with beneficiary coords.
      controller.add(batch);
      await Future<void>.delayed(Duration.zero);

      await notifier.confirmPickup('b1', XFile('/fake/photo.jpg'));

      // ETA destination should now point to beneficiary.
      expect(notifier.etaDestinationForTest, (benLat, benLng));
      expect(
        container.read(driverProvider).rescuePhase,
        ClaimRescuePhase.enRouteBeneficiary,
      );
    },
  );
}
