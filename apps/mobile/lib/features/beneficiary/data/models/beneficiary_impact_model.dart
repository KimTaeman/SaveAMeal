import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';

class BeneficiaryImpactModel {
  const BeneficiaryImpactModel({
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
  final Map<String, double> byCategory; // raw string keys from Firestore

  factory BeneficiaryImpactModel.fromFirestore(Map<String, dynamic> data) {
    final rawCategory =
        (data['byCategory'] as Map<String, dynamic>?) ?? const {};
    final byCategory = <String, double>{
      for (final entry in rawCategory.entries)
        entry.key: (entry.value as num? ?? 0).toDouble(),
    };
    return BeneficiaryImpactModel(
      totalMeals: (data['totalMeals'] as num? ?? 0).toInt(),
      totalKg: (data['totalKg'] as num? ?? 0).toDouble(),
      totalCo2e: (data['totalCo2e'] as num? ?? 0).toDouble(),
      totalDeliveries: (data['totalDeliveries'] as num? ?? 0).toInt(),
      byCategory: byCategory,
    );
  }

  BeneficiaryImpact toEntity() {
    final mapped = <FoodCategory, double>{};
    for (final entry in byCategory.entries) {
      try {
        final category = FoodCategory.values.byName(entry.key);
        mapped[category] = entry.value;
      } on ArgumentError {
        // Unknown category key from Firestore — skip silently.
      }
    }
    return BeneficiaryImpact(
      totalMeals: totalMeals,
      totalKg: totalKg,
      totalCo2e: totalCo2e,
      totalDeliveries: totalDeliveries,
      byCategory: mapped,
    );
  }
}
