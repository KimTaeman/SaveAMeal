// Pure Dart — zero Flutter or backend imports.

import 'package:saveameal/features/beneficiary/domain/entities/intake_item.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';

class IntakeRequestDetail {
  const IntakeRequestDetail({
    required this.batchId,
    required this.beneficiaryId,
    required this.donorId,
    required this.status,
    required this.portions,
    required this.weightKg,
    required this.items,
    this.donorName,
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
  final String? donorName;
  final IntakeStatus status;
  final int portions;
  final double weightKg;
  final List<IntakeItem> items;

  /// Same value as the Firestore `driverId` field.
  /// Used as the key for `driverLocationProvider` to show the live map marker.
  final String? volunteerId;

  final String? volunteerName;
  final int? estimatedArrivalMinutes;
  final String? cancellationReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
