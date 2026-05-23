import 'package:freezed_annotation/freezed_annotation.dart';

part 'driver_location_model.freezed.dart';
part 'driver_location_model.g.dart';

@freezed
sealed class DriverLocationModel with _$DriverLocationModel {
  const factory DriverLocationModel({
    required String driverId,
    required double lat,
    required double lng,
    DateTime? updatedAt,
  }) = _DriverLocationModel;

  factory DriverLocationModel.fromJson(Map<String, dynamic> json) =>
      _$DriverLocationModelFromJson(json);
}
