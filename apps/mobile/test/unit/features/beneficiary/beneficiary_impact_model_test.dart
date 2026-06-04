import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/data/models/beneficiary_impact_model.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';

void main() {
  group('BeneficiaryImpactModel.fromFirestore', () {
    test('maps full document with all fields present', () {
      final data = {
        'totalMeals': 8420,
        'totalKg': 3100.0,
        'totalCo2e': 3100.0,
        'totalDeliveries': 47,
        'byCategory': {
          'bakery': 465.0,
          'produce': 930.0,
          'dairy': 0.0,
          'meat': 0.0,
          'beverages': 0.0,
          'other': 1705.0,
        },
      };

      final model = BeneficiaryImpactModel.fromFirestore(data);

      expect(model.totalMeals, 8420);
      expect(model.totalKg, 3100.0);
      expect(model.totalCo2e, 3100.0);
      expect(model.totalDeliveries, 47);
      expect(model.byCategory['bakery'], 465.0);
      expect(model.byCategory['produce'], 930.0);
      expect(model.byCategory['other'], 1705.0);
    });

    test('defaults to zero for absent fields (partial document)', () {
      final model = BeneficiaryImpactModel.fromFirestore({'totalMeals': 5});

      expect(model.totalMeals, 5);
      expect(model.totalKg, 0.0);
      expect(model.totalCo2e, 0.0);
      expect(model.totalDeliveries, 0);
      expect(model.byCategory, isEmpty);
    });

    test('defaults to empty map when byCategory key is absent', () {
      final model = BeneficiaryImpactModel.fromFirestore({
        'totalMeals': 10,
        'totalKg': 4.0,
        'totalCo2e': 4.0,
        'totalDeliveries': 1,
      });

      expect(model.byCategory, isEmpty);
    });

    test('handles completely empty document', () {
      final model = BeneficiaryImpactModel.fromFirestore({});

      expect(model.totalMeals, 0);
      expect(model.totalKg, 0.0);
      expect(model.totalCo2e, 0.0);
      expect(model.totalDeliveries, 0);
      expect(model.byCategory, isEmpty);
    });
  });

  group('BeneficiaryImpactModel.toEntity', () {
    test('maps known string keys to FoodCategory enum values', () {
      final model = BeneficiaryImpactModel(
        totalMeals: 100,
        totalKg: 40.0,
        totalCo2e: 40.0,
        totalDeliveries: 2,
        byCategory: {
          'bakery': 10.0,
          'produce': 20.0,
          'dairy': 5.0,
          'meat': 3.0,
          'beverages': 2.0,
          'other': 0.0,
        },
      );

      final entity = model.toEntity();

      expect(entity.byCategory[FoodCategory.bakery], 10.0);
      expect(entity.byCategory[FoodCategory.produce], 20.0);
      expect(entity.byCategory[FoodCategory.dairy], 5.0);
      expect(entity.byCategory[FoodCategory.meat], 3.0);
      expect(entity.byCategory[FoodCategory.beverages], 2.0);
      expect(entity.byCategory[FoodCategory.other], 0.0);
    });

    test('silently skips unknown category keys', () {
      final model = BeneficiaryImpactModel(
        totalMeals: 10,
        totalKg: 4.0,
        totalCo2e: 4.0,
        totalDeliveries: 1,
        byCategory: {'unknown_future_category': 7.0, 'bakery': 3.0},
      );

      final entity = model.toEntity();

      expect(entity.byCategory.length, 1);
      expect(entity.byCategory[FoodCategory.bakery], 3.0);
    });

    test('produces BeneficiaryImpact with correct scalar fields', () {
      final model = BeneficiaryImpactModel(
        totalMeals: 50,
        totalKg: 20.0,
        totalCo2e: 18.5,
        totalDeliveries: 3,
        byCategory: {},
      );

      final entity = model.toEntity();

      expect(entity.totalMeals, 50);
      expect(entity.totalKg, 20.0);
      expect(entity.totalCo2e, 18.5);
      expect(entity.totalDeliveries, 3);
    });

    test('empty model produces BeneficiaryImpact matching .empty', () {
      final model = BeneficiaryImpactModel(
        totalMeals: 0,
        totalKg: 0.0,
        totalCo2e: 0.0,
        totalDeliveries: 0,
        byCategory: {},
      );

      final entity = model.toEntity();

      expect(entity.totalMeals, BeneficiaryImpact.empty.totalMeals);
      expect(entity.totalKg, BeneficiaryImpact.empty.totalKg);
      expect(entity.totalCo2e, BeneficiaryImpact.empty.totalCo2e);
      expect(entity.totalDeliveries, BeneficiaryImpact.empty.totalDeliveries);
      expect(entity.byCategory, isEmpty);
    });
  });
}
