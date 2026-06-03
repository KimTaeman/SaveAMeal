import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';
import 'package:saveameal/features/donor/domain/usecases/watch_batch_by_id_usecase.dart';

class _FakeDonorRepository implements DonorRepository {
  final Batch? batch;
  _FakeDonorRepository({this.batch});

  @override
  Stream<List<Batch>> watchActiveBatches(String donorId) =>
      Stream.value(batch != null ? [batch!] : []);
  @override
  Stream<DonorMetrics> watchMetrics(String donorId) =>
      Stream.value(DonorMetrics.empty);
  @override
  Future<void> createBatch(Batch b) async {}
  @override
  Stream<List<Beneficiary>> getBeneficiaries() => const Stream.empty();
  @override
  Stream<List<Batch>> watchAllBatches(String donorId) =>
      Stream.value(batch != null ? [batch!] : []);
  @override
  Stream<Batch> watchBatchById(String batchId) => batch != null
      ? Stream.value(batch!)
      : Stream.error(Exception('not found'));
}

void main() {
  group('WatchBatchByIdUsecase', () {
    test('delegates to repository and emits Batch', () async {
      final b = Batch(
        id: 'batch001',
        donorId: 'donor-1',
        items: const [],
        pickupAddress: '1 Test St',
        status: BatchStatus.claimed,
        volunteerName: 'Nattapong',
        createdAt: DateTime(2026, 5, 23),
      );
      final usecase = WatchBatchByIdUsecase(_FakeDonorRepository(batch: b));

      final result = await usecase.call('batch001').first;

      expect(result.id, 'batch001');
      expect(result.status, BatchStatus.claimed);
      expect(result.volunteerName, 'Nattapong');
    });

    test('emits error when repository stream errors', () async {
      final usecase = WatchBatchByIdUsecase(_FakeDonorRepository(batch: null));

      expect(usecase.call('missing'), emitsError(isA<Exception>()));
    });
  });
}
