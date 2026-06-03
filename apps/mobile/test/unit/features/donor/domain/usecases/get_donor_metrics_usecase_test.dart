import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';
import 'package:saveameal/features/donor/domain/usecases/get_donor_metrics_usecase.dart';

class _FakeDonorRepository implements DonorRepository {
  final DonorMetrics metricsToEmit;
  _FakeDonorRepository({required this.metricsToEmit});

  @override
  Stream<List<Batch>> watchActiveBatches(String donorId) =>
      const Stream.empty();

  @override
  Stream<DonorMetrics> watchMetrics(String donorId) =>
      Stream.value(metricsToEmit);

  @override
  Future<void> createBatch(Batch batch) async {}

  @override
  Stream<List<Beneficiary>> getBeneficiaries() => const Stream.empty();

  @override
  Stream<List<Batch>> watchAllBatches(String donorId) => const Stream.empty();

  @override
  Stream<Batch> watchBatchById(String batchId) => const Stream.empty();
}

void main() {
  group('GetDonorMetricsUsecase', () {
    test(
      'delegates to repository.watchMetrics and emits DonorMetrics',
      () async {
        const metrics = DonorMetrics(
          donorId: 'donor-abc',
          totalKg: 150.0,
          totalMeals: 300,
          totalCO2e: 45.0,
          totalDeliveries: 12,
        );
        final repo = _FakeDonorRepository(metricsToEmit: metrics);
        final usecase = GetDonorMetricsUsecase(repo);

        final emitted = await usecase.call('donor-abc').first;

        expect(emitted.donorId, equals('donor-abc'));
        expect(emitted.totalKg, equals(150.0));
        expect(emitted.totalMeals, equals(300));
        expect(emitted.totalDeliveries, equals(12));
      },
    );

    test(
      'emits DonorMetrics.empty when repository emits empty metrics',
      () async {
        final repo = _FakeDonorRepository(metricsToEmit: DonorMetrics.empty);
        final usecase = GetDonorMetricsUsecase(repo);

        final emitted = await usecase.call('donor-abc').first;

        expect(emitted.totalKg, equals(0.0));
        expect(emitted.totalMeals, equals(0));
        expect(emitted.totalDeliveries, equals(0));
      },
    );
  });
}
