import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/domain/usecases/update_batch_eta_usecase.dart';

class _FakeRepo implements DriverRepository {
  int updateBatchEtaCallCount = 0;
  int? lastEtaWritten;

  @override
  Future<void> updateBatchEta(String batchId, int eta) async {
    updateBatchEtaCallCount++;
    lastEtaWritten = eta;
  }

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
  Future<void> deleteLocation(String driverId) async {}
  @override
  Stream<int> watchPoints(String uid) => const Stream.empty();
}

void main() {
  // Bangkok city centre → Siam Paragon (~2 km apart, ETA ≈ 6 min at defaults)
  const driverLat = 13.7500, driverLng = 100.5000;
  const destLat = 13.7680, destLng = 100.5000;

  late _FakeRepo repo;
  late UpdateBatchEtaUsecase usecase;

  setUp(() {
    repo = _FakeRepo();
    usecase = UpdateBatchEtaUsecase(repo);
  });

  group('UpdateBatchEtaUsecase', () {
    test('writes ETA on first call (lastEtaMinutes == null)', () async {
      final result = await usecase.call(
        batchId: 'b1',
        driverLat: driverLat,
        driverLng: driverLng,
        destLat: destLat,
        destLng: destLng,
        lastEtaMinutes: null,
      );

      expect(result, isNotNull);
      expect(result, greaterThan(0));
      expect(repo.updateBatchEtaCallCount, 1);
      expect(repo.lastEtaWritten, result);
    });

    test('returns null and skips write when ETA is unchanged', () async {
      // First call to learn the ETA.
      final firstEta = await usecase.call(
        batchId: 'b1',
        driverLat: driverLat,
        driverLng: driverLng,
        destLat: destLat,
        destLng: destLng,
        lastEtaMinutes: null,
      );

      // Second call with the same coordinates — ETA is identical.
      final result = await usecase.call(
        batchId: 'b1',
        driverLat: driverLat,
        driverLng: driverLng,
        destLat: destLat,
        destLng: destLng,
        lastEtaMinutes: firstEta,
      );

      expect(result, isNull);
      expect(repo.updateBatchEtaCallCount, 1); // only the first call wrote
    });

    test('writes again when ETA changes', () async {
      // Seed with a last ETA that doesn't match the computed one.
      const differentLastEta = 99;

      final result = await usecase.call(
        batchId: 'b1',
        driverLat: driverLat,
        driverLng: driverLng,
        destLat: destLat,
        destLng: destLng,
        lastEtaMinutes: differentLastEta,
      );

      expect(result, isNotNull);
      expect(result, isNot(differentLastEta));
      expect(repo.updateBatchEtaCallCount, 1);
    });

    test('returned value equals the value written to the repository', () async {
      final result = await usecase.call(
        batchId: 'b1',
        driverLat: driverLat,
        driverLng: driverLng,
        destLat: destLat,
        destLng: destLng,
        lastEtaMinutes: null,
      );

      expect(result, repo.lastEtaWritten);
    });
  });
}
