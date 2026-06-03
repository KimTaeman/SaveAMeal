import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_impact_repository.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/watch_beneficiary_impact_usecase.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';

class _FakeBeneficiaryImpactRepository implements BeneficiaryImpactRepository {
  _FakeBeneficiaryImpactRepository({required this.impactToEmit});

  final BeneficiaryImpact impactToEmit;
  String? lastCalledBeneficiaryId;

  @override
  Stream<BeneficiaryImpact> watchImpact(String beneficiaryId) {
    lastCalledBeneficiaryId = beneficiaryId;
    return Stream.value(impactToEmit);
  }
}

void main() {
  group('WatchBeneficiaryImpactUsecase', () {
    test('delegates call to repository.watchImpact with the correct id', () {
      const impact = BeneficiaryImpact(
        totalMeals: 42,
        totalKg: 16.8,
        totalCo2e: 14.0,
        totalDeliveries: 2,
        byCategory: {},
      );
      final repo = _FakeBeneficiaryImpactRepository(impactToEmit: impact);
      final usecase = WatchBeneficiaryImpactUsecase(repo);

      usecase.call('ben-001');

      expect(repo.lastCalledBeneficiaryId, 'ben-001');
    });

    test('re-emits the impact value from the repository unchanged', () async {
      const expected = BeneficiaryImpact(
        totalMeals: 100,
        totalKg: 40.0,
        totalCo2e: 36.0,
        totalDeliveries: 5,
        byCategory: {FoodCategory.bakery: 15.0, FoodCategory.produce: 25.0},
      );
      final repo = _FakeBeneficiaryImpactRepository(impactToEmit: expected);
      final usecase = WatchBeneficiaryImpactUsecase(repo);

      final emitted = await usecase.call('ben-002').first;

      expect(emitted.totalMeals, expected.totalMeals);
      expect(emitted.totalKg, expected.totalKg);
      expect(emitted.totalCo2e, expected.totalCo2e);
      expect(emitted.totalDeliveries, expected.totalDeliveries);
      expect(
        emitted.byCategory[FoodCategory.bakery],
        expected.byCategory[FoodCategory.bakery],
      );
    });

    test('emits BeneficiaryImpact.empty when repository emits empty', () async {
      final repo = _FakeBeneficiaryImpactRepository(
        impactToEmit: BeneficiaryImpact.empty,
      );
      final usecase = WatchBeneficiaryImpactUsecase(repo);

      final emitted = await usecase.call('ben-003').first;

      expect(emitted.totalMeals, 0);
      expect(emitted.totalKg, 0.0);
      expect(emitted.byCategory, isEmpty);
    });
  });
}
