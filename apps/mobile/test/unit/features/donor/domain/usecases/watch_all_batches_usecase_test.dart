import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';
import 'package:saveameal/features/donor/domain/usecases/watch_all_batches_usecase.dart';

class _FakeDonorRepository implements DonorRepository {
  final List<Batch> batches;
  _FakeDonorRepository({required this.batches});

  @override
  Stream<List<Batch>> watchActiveBatches(String donorId) =>
      Stream.value(batches);
  @override
  Stream<DonorMetrics> watchMetrics(String donorId) =>
      Stream.value(DonorMetrics.empty);
  @override
  Future<void> createBatch(Batch batch) async {}
  @override
  Stream<List<Beneficiary>> getBeneficiaries() => const Stream.empty();
  @override
  Stream<List<Batch>> watchAllBatches(String donorId) => Stream.value(batches);
  @override
  Stream<Batch> watchBatchById(String batchId) =>
      Stream.value(batches.firstWhere((b) => b.id == batchId));
}

Batch _makeBatch(String id, BatchStatus status) => Batch(
  id: id,
  donorId: 'donor-1',
  items: const [],
  pickupAddress: '1 Test St',
  status: status,
  createdAt: DateTime(2026, 5, 23),
);

void main() {
  group('WatchAllBatchesUsecase', () {
    test(
      'delegates to repository.watchAllBatches and emits all statuses',
      () async {
        final batches = [
          _makeBatch('aaaaaaaa', BatchStatus.open),
          _makeBatch('bbbbbbbb', BatchStatus.closed),
          _makeBatch('cccccccc', BatchStatus.delivered),
        ];
        final usecase = WatchAllBatchesUsecase(
          _FakeDonorRepository(batches: batches),
        );

        final result = await usecase.call('donor-1').first;

        expect(result.length, 3);
        expect(
          result.map((b) => b.id),
          containsAll(['aaaaaaaa', 'bbbbbbbb', 'cccccccc']),
        );
      },
    );

    test('emits empty list when repository emits empty list', () async {
      final usecase = WatchAllBatchesUsecase(_FakeDonorRepository(batches: []));

      final result = await usecase.call('donor-1').first;

      expect(result, isEmpty);
    });
  });
}
