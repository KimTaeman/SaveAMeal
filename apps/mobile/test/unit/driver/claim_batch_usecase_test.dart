import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/core/exceptions/batch_exceptions.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/domain/usecases/claim_batch_usecase.dart';

class _FakeDriverRepository implements DriverRepository {
  bool shouldThrow = false;
  String? lastClaimedBatchId;
  String? lastClaimedDriverId;

  @override
  Future<void> claimBatch(String batchId, String driverId) async {
    if (shouldThrow) throw const BatchAlreadyClaimedException();
    lastClaimedBatchId = batchId;
    lastClaimedDriverId = driverId;
  }

  @override
  Stream<List<BatchSummary>> getOpenBatches() => const Stream.empty();

  @override
  Stream<BatchSummary?> getActiveBatch(String driverId) => const Stream.empty();

  @override
  Future<void> confirmPickup(String batchId, String photoUrl) async {}

  @override
  Future<void> confirmDelivery(String batchId, String? notes) async {}

  @override
  Future<void> upsertLocation(String driverId, double lat, double lng) async {}

  @override
  Stream<int> watchPoints(String uid) => const Stream.empty();
}

void main() {
  late _FakeDriverRepository repo;
  late ClaimBatchUsecase usecase;

  setUp(() {
    repo = _FakeDriverRepository();
    usecase = ClaimBatchUsecase(repo);
  });

  test('calls repository with correct batchId and driverId', () async {
    await usecase('batch-1', 'driver-1');
    expect(repo.lastClaimedBatchId, 'batch-1');
    expect(repo.lastClaimedDriverId, 'driver-1');
  });

  test('propagates BatchAlreadyClaimedException', () async {
    repo.shouldThrow = true;
    await expectLater(
      () => usecase('batch-1', 'driver-1'),
      throwsA(isA<BatchAlreadyClaimedException>()),
    );
  });
}
