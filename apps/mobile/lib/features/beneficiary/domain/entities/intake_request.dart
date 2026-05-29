// Pure Dart — zero Flutter or Firebase imports.

enum IntakeStatus { pending, dispatched, collected, cancelled }

enum BeneficiaryIntakeAvailability { accepting, fullBusy }

class IntakeRequest {
  const IntakeRequest({
    required this.batchId,
    required this.beneficiaryId,
    required this.donorId,
    required this.status,
    required this.portions,
    required this.mealDescription,
    required this.weightKg,
    this.volunteerId,
    this.volunteerName,
    this.estimatedArrivalMinutes,
    this.cancellationReason,
    this.createdAt,
    this.updatedAt,
  });

  final String batchId;
  final String beneficiaryId;
  final String donorId;
  final IntakeStatus status;
  final int portions;
  final String mealDescription;
  final double weightKg;
  final String? volunteerId;
  final String? volunteerName;
  final int? estimatedArrivalMinutes;
  final String? cancellationReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
