import 'package:freezed_annotation/freezed_annotation.dart';

part 'batch_model.freezed.dart';
part 'batch_model.g.dart';

enum BatchStatus { open, claimed, pickedUp, delivered, closed }

@freezed
sealed class BatchModel with _$BatchModel {
  const factory BatchModel({
    required String id,
    required String donorId,
    required String description,
    required double weightKg,
    required int portions,
    required String pickupAddress,
    required BatchStatus status,
    String? driverId,
    String? beneficiaryId,
    String? photoUrl,
    String? qrCode,
    int? rating,
    String? feedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _BatchModel;

  factory BatchModel.fromJson(Map<String, dynamic> json) =>
      _$BatchModelFromJson(json);
}
