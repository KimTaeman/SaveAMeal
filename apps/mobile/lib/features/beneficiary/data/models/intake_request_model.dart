import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';

part 'intake_request_model.freezed.dart';
part 'intake_request_model.g.dart';

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
    status: _mapStatus(status),
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

  static IntakeStatus _mapStatus(String raw) => switch (raw) {
    'open' => IntakeStatus.pending,
    'claimed' => IntakeStatus.dispatched,
    'pickedUp' => IntakeStatus.dispatched,
    'delivered' => IntakeStatus.collected,
    'closed' => IntakeStatus.collected,
    'cancelled' => IntakeStatus.cancelled,
    _ => IntakeStatus.pending,
  };
}
