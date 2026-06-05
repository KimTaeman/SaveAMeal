import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/shared/domain/entities/food_category.dart';

void main() {
  group('FoodCategory.fromString', () {
    test('parses all known values by enum name', () {
      expect(FoodCategory.fromString('bakery'), FoodCategory.bakery);
      expect(FoodCategory.fromString('produce'), FoodCategory.produce);
      expect(FoodCategory.fromString('dairy'), FoodCategory.dairy);
      expect(FoodCategory.fromString('meat'), FoodCategory.meat);
      expect(FoodCategory.fromString('beverages'), FoodCategory.beverages);
      expect(FoodCategory.fromString('other'), FoodCategory.other);
    });

    test('unknown string falls back to FoodCategory.other', () {
      expect(FoodCategory.fromString('unknown'), FoodCategory.other);
      expect(
        FoodCategory.fromString('Bakery'),
        FoodCategory.other,
      ); // case-sensitive
      expect(FoodCategory.fromString('PRODUCE'), FoodCategory.other);
    });

    test('empty string falls back to FoodCategory.other', () {
      expect(FoodCategory.fromString(''), FoodCategory.other);
    });

    test('covers all enum values — no value is unreachable by name', () {
      for (final category in FoodCategory.values) {
        expect(FoodCategory.fromString(category.name), category);
      }
    });
  });
}
