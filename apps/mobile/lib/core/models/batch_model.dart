import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:saveameal/core/models/batch_item_model.dart';

part 'batch_model.freezed.dart';
part 'batch_model.g.dart';

enum BatchStatus { open, claimed, pickedUp, delivered, closed, cancelled }

@freezed
sealed class BatchModel with _$BatchModel {
  const factory BatchModel({
    required String id,
    required String donorId,
    @Default([]) List<BatchItemModel> items,
    required String pickupAddress,
    required BatchStatus status,
    String? driverId,
    String? volunteerName,
    String? beneficiaryId,
    // Denormalised beneficiary info (written at batch creation time)
    String? beneficiaryName,
    String? beneficiaryAddress,
    // Donor display info
    String? donorName,
    String? donorContact,
    // Scheduling
    String? pickupWindowStart,
    String? pickupWindowEnd,
    String? specialInstructions,
    // Lifecycle timestamps
    DateTime? claimedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    // Photos & QR
    String? photoUrl,
    String? pickupPhotoUrl,
    String? qrCode,
    // Delivery outcome
    String? deliveryNotes,
    int? rating,
    String? feedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _BatchModel;

  factory BatchModel.fromJson(Map<String, dynamic> json) =>
      _$BatchModelFromJson(json);
}
