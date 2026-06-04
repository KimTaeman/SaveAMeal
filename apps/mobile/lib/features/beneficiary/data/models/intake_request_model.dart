import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_item.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';

part 'intake_request_model.freezed.dart';
part 'intake_request_model.g.dart';

/// Package-accessible status mapper shared by both `toDomain()` and
/// `batchModelToDetailDomain`.
IntakeStatus mapIntakeStatus(String raw) => switch (raw) {
  'open' => IntakeStatus.pending,
  'claimed' => IntakeStatus.dispatched,
  'pickedUp' => IntakeStatus.dispatched,
  'delivered' => IntakeStatus.collected,
  'closed' => IntakeStatus.collected,
  'cancelled' => IntakeStatus.cancelled,
  _ => IntakeStatus.pending,
};

/// Maps a [BatchModel] directly to [IntakeRequestDetail] (item-level detail).
IntakeRequestDetail batchModelToDetailDomain(BatchModel batch) {
  final items = batch.items
      .map(
        (i) => IntakeItem(
          name: i.name,
          category: i.category,
          weightKg: i.weightKg,
        ),
      )
      .toList();
  return IntakeRequestDetail(
    batchId: batch.id,
    beneficiaryId: batch.beneficiaryId ?? '',
    donorId: batch.donorId,
    donorName: batch.donorName,
    status: mapIntakeStatus(batch.status.name),
    portions: items.length,
    weightKg: items.fold(0.0, (sum, i) => sum + i.weightKg),
    items: items,
    volunteerId: batch.driverId,
    volunteerName: batch.volunteerName,
    estimatedArrivalMinutes: null,
    cancellationReason: null,
    createdAt: batch.createdAt,
    updatedAt: batch.updatedAt,
  );
}

@freezed
sealed class IntakeRequestModel with _$IntakeRequestModel {
  const factory IntakeRequestModel({
    required String batchId,
    required String beneficiaryId,
    required String donorId,
    required String status,
    required int portions,
    required String mealDescription,
    required double weightKg,
    String? driverId,
    String? volunteerName,
    int? estimatedArrivalMinutes,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _IntakeRequestModel;

  factory IntakeRequestModel.fromJson(Map<String, dynamic> json) =>
      _$IntakeRequestModelFromJson(json);

  factory IntakeRequestModel.fromBatch(
    BatchModel batch, {
    String? volunteerName,
    int? estimatedArrivalMinutes,
  }) => IntakeRequestModel(
    batchId: batch.id,
    beneficiaryId: batch.beneficiaryId ?? '',
    donorId: batch.donorId,
    status: batch.status.name,
    portions: batch.items.length,
    mealDescription: batch.items.map((i) => i.name).join(', '),
    weightKg: batch.items.fold(0.0, (sum, i) => sum + i.weightKg),
    driverId: batch.driverId,
    volunteerName: volunteerName,
    estimatedArrivalMinutes: estimatedArrivalMinutes,
    cancellationReason: null,
    createdAt: batch.createdAt,
    updatedAt: batch.updatedAt,
  );
}

extension IntakeRequestModelX on IntakeRequestModel {
  IntakeRequest toDomain() => IntakeRequest(
    batchId: batchId,
    beneficiaryId: beneficiaryId,
    donorId: donorId,
    status: mapIntakeStatus(status),
    portions: portions,
    mealDescription: mealDescription,
    weightKg: weightKg,
    volunteerId: driverId,
    volunteerName: volunteerName,
    estimatedArrivalMinutes: estimatedArrivalMinutes,
    cancellationReason: cancellationReason,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
