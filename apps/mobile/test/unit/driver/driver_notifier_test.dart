import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Stream<BatchSummary?> getActiveBatch(String driverId) => const Stream.empty();

  @override
  Future<void> upsertLocation(String driverId, double lat, double lng) async {}

  @override
  Stream<int> watchPoints(String uid) => const Stream.empty();
}

class _FakeDatasource implements DriverRemoteDatasource {
  @override
  Future<String> uploadPickupPhoto(String batchId, String localPath) async =>
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
    await notifier.confirmPickup('b1', '/fake/path.jpg');
    expect(
      container.read(driverProvider).rescuePhase,
      ClaimRescuePhase.enRouteBeneficiary,
    );
    await notifier.confirmDelivery('b1', null);
    expect(container.read(driverProvider).step, DriverStep.delivered);
  });
}
