import 'package:freezed_annotation/freezed_annotation.dart';

part 'impact_metrics_model.freezed.dart';
part 'impact_metrics_model.g.dart';

@freezed
class ImpactMetricsModel with _$ImpactMetricsModel {
  const factory ImpactMetricsModel({
    required String id,
    @Default(0.0) double totalKg,
    @Default(0) int totalMeals,
    @Default(0.0) double totalCO2e,
    @Default(0) int totalDeliveries,
  }) = _ImpactMetricsModel;

  factory ImpactMetricsModel.fromJson(Map<String, dynamic> json) =>
      _$ImpactMetricsModelFromJson(json);
}
