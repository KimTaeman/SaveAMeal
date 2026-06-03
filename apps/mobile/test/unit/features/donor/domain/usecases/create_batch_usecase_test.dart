import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/batch_item.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';
import 'package:saveameal/features/donor/domain/usecases/create_batch_usecase.dart';

class _FakeDonorRepository implements DonorRepository {
  Batch? lastCreatedBatch;

  @override
  Stream<List<Batch>> watchActiveBatches(String donorId) =>
      const Stream.empty();

  @override
  Stream<DonorMetrics> watchMetrics(String donorId) => const Stream.empty();

  @override
  Future<void> createBatch(Batch batch) async {
    lastCreatedBatch = batch;
  }

  @override
  Stream<List<Beneficiary>> getBeneficiaries() => const Stream.empty();

  @override
  Stream<List<Batch>> watchAllBatches(String donorId) => const Stream.empty();

  @override
  Stream<Batch> watchBatchById(String batchId) => const Stream.empty();
}

final _testItem = BatchItem(
  name: 'Rice and vegetables',
  category: FoodCategory.produce,
  weightKg: 12.5,
  expiryTime: DateTime(2026, 5, 24, 18, 0),
);

void main() {
  group('CreateBatchUsecase', () {
    late _FakeDonorRepository repo;
    late CreateBatchUsecase usecase;

    setUp(() {
      repo = _FakeDonorRepository();
      usecase = CreateBatchUsecase(repo);
    });

    test(
      'delegates to repository.createBatch with the correct Batch',
      () async {
        final batch = Batch(
          id: 'test-id-1234',
          donorId: 'donor-abc',
          items: [_testItem],
          pickupAddress: '123 Main St',
          status: BatchStatus.open,
          createdAt: DateTime(2026, 5, 23),
        );

        await usecase.call(batch);

        expect(repo.lastCreatedBatch, equals(batch));
        expect(repo.lastCreatedBatch?.id, equals('test-id-1234'));
        expect(repo.lastCreatedBatch?.portions, equals(1));
        expect(repo.lastCreatedBatch?.weightKg, equals(12.5));
      },
    );
  });
}
