import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';
import 'package:saveameal/features/donor/domain/usecases/watch_active_batches_usecase.dart';

class _FakeDonorRepository implements DonorRepository {
  final List<Batch> batchesToEmit;
  _FakeDonorRepository({required this.batchesToEmit});

  @override
  Stream<List<Batch>> watchActiveBatches(String donorId) =>
      Stream.value(batchesToEmit);

  @override
  Stream<DonorMetrics> watchMetrics(String donorId) =>
      Stream.value(DonorMetrics.empty);

  @override
  Future<void> createBatch(Batch batch) async {}

  @override
  Stream<List<Beneficiary>> getBeneficiaries() => const Stream.empty();
}

Batch _makeBatch(String id) => Batch(
  id: id,
  donorId: 'donor-abc',
  items: const [],
  pickupAddress: '1 Test St',
  status: BatchStatus.open,
  createdAt: DateTime(2026, 5, 23),
);

void main() {
  group('WatchActiveBatchesUsecase', () {
    test(
      'delegates to repository.watchActiveBatches and emits List<Batch>',
      () async {
        final batches = [_makeBatch('id-1'), _makeBatch('id-2')];
        final repo = _FakeDonorRepository(batchesToEmit: batches);
        final usecase = WatchActiveBatchesUsecase(repo);

        final emitted = await usecase.call('donor-abc').first;

        expect(emitted.length, equals(2));
        expect(emitted[0].id, equals('id-1'));
        expect(emitted[1].id, equals('id-2'));
      },
    );

    test('emits empty list when repository emits empty list', () async {
      final repo = _FakeDonorRepository(batchesToEmit: []);
      final usecase = WatchActiveBatchesUsecase(repo);

      final emitted = await usecase.call('donor-abc').first;

      expect(emitted, isEmpty);
    });
  });
}
