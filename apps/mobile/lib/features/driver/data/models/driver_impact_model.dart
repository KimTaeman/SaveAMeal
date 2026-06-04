import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:saveameal/features/driver/domain/entities/driver_impact.dart';

part 'driver_impact_model.freezed.dart';
part 'driver_impact_model.g.dart';

@freezed
sealed class DriverImpactModel with _$DriverImpactModel {
  const factory DriverImpactModel({
    @Default(0) int rank,
    @Default(0) int totalDrivers,
    @Default(0) int mealsSaved,
    @Default(0) int sproutPoints,
    @Default(0) int rankProgressCurrent,
    @Default(100) int rankProgressTarget,
    @Default('Bronze') String currentRankName,
    @Default('Silver') String nextRankName,
  }) = _DriverImpactModel;

  factory DriverImpactModel.fromJson(Map<String, dynamic> json) =>
      _$DriverImpactModelFromJson(json);
}

extension DriverImpactModelX on DriverImpactModel {
  DriverImpact toEntity() => DriverImpact(
    rank: rank,
    totalDrivers: totalDrivers,
    mealsSaved: mealsSaved,
    sproutPoints: sproutPoints,
    rankProgressCurrent: rankProgressCurrent,
    rankProgressTarget: rankProgressTarget,
    currentRankName: currentRankName,
    nextRankName: nextRankName,
  );
}
