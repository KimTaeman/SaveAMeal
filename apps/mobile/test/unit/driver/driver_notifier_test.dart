import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saveameal/core/exceptions/batch_exceptions.dart';
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

ProviderContainer _makeContainer(_FakeRepo repo) => ProviderContainer(
  overrides: [driverRepositoryProvider.overrideWithValue(repo)],
);

void main() {
  test('initial state is browsing', () {
    final container = _makeContainer(_FakeRepo());
    expect(container.read(driverNotifierProvider).step, DriverStep.browsing);
  });

  test('claimBatch transitions step to claimed', () async {
    final container = _makeContainer(_FakeRepo());
    await container
        .read(driverNotifierProvider.notifier)
        .claimBatch('b1', 'd1');
    expect(container.read(driverNotifierProvider).step, DriverStep.claimed);
  });

  test(
    'claimBatch with conflict rethrows BatchAlreadyClaimedException',
    () async {
      final repo = _FakeRepo()..claimShouldThrow = true;
      final container = _makeContainer(repo);
      await expectLater(
        () => container
            .read(driverNotifierProvider.notifier)
            .claimBatch('b1', 'd1'),
        throwsA(isA<BatchAlreadyClaimedException>()),
      );
    },
  );

  test('confirmDelivery transitions step to delivered', () async {
    final container = _makeContainer(_FakeRepo());
    final notifier = container.read(driverNotifierProvider.notifier);
    await notifier.claimBatch('b1', 'd1');
    await notifier.confirmPickup('b1', '/fake/path.jpg');
    await notifier.confirmDelivery('b1', null);
    expect(container.read(driverNotifierProvider).step, DriverStep.delivered);
  });
}
