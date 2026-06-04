// Pure Dart entity — no Flutter or backend imports.
import 'package:saveameal/shared/domain/entities/food_category.dart';

class BeneficiaryImpact {
  const BeneficiaryImpact({
    required this.totalMeals,
    required this.totalKg,
    required this.totalCo2e,
    required this.totalDeliveries,
    required this.byCategory,
  });

  final int totalMeals;
  final double totalKg;
  final double totalCo2e;
  final int totalDeliveries;
  final Map<FoodCategory, double> byCategory; // category → kg

  static const empty = BeneficiaryImpact(
    totalMeals: 0,
    totalKg: 0,
    totalCo2e: 0,
    totalDeliveries: 0,
    byCategory: {},
  );
}
