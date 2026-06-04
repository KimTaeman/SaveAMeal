import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/shared/domain/entities/food_category.dart';

part 'beneficiary_impact_model.freezed.dart';
part 'beneficiary_impact_model.g.dart';

@freezed
abstract class BeneficiaryImpactModel with _$BeneficiaryImpactModel {
  const BeneficiaryImpactModel._();

  const factory BeneficiaryImpactModel({
    required int totalMeals,
    required double totalKg,
    required double totalCo2e,
    required int totalDeliveries,
    /// Raw string-keyed category map from Firestore/JSON.
    @Default({}) Map<String, double> byCategory,
  }) = _BeneficiaryImpactModel;

  /// Constructs from a raw Firestore document data map.
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

  factory BeneficiaryImpactModel.fromJson(Map<String, dynamic> json) =>
      _$BeneficiaryImpactModelFromJson(json);

  /// Maps the model to the domain entity, converting raw string keys to
  /// [FoodCategory] enum values.
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
