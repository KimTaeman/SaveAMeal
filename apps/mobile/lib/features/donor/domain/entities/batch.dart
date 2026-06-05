import 'package:saveameal/features/donor/domain/entities/batch_item.dart';
import 'package:saveameal/shared/domain/entities/batch_status.dart';

export 'package:saveameal/shared/domain/entities/batch_status.dart';

class Batch {
  const Batch({
    required this.id,
    required this.donorId,
    required this.items,
    required this.pickupAddress,
    required this.status,
    this.driverId,
    this.volunteerName,
    this.beneficiaryId,
    this.beneficiaryName,
    this.beneficiaryAddress,
    this.donorName,
    this.pickupLat = 0.0,
    this.pickupLng = 0.0,
    this.pickupWindowStart,
    this.pickupWindowEnd,
    this.specialInstructions,
    this.photoUrl,
    this.pickupPhotoUrl,
    this.qrCode,
    this.claimedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.deliveryNotes,
    this.rating,
    this.feedback,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String donorId;
  final List<BatchItem> items;
  final String pickupAddress;
  final BatchStatus status;
  final String? driverId;
  final String? volunteerName;
  final String? beneficiaryId;
  final String? beneficiaryName;
  final String? beneficiaryAddress;
  final String? donorName;
  final double pickupLat;
  final double pickupLng;
  final String? pickupWindowStart;
  final String? pickupWindowEnd;
  final String? specialInstructions;
  final String? photoUrl;
  final String? pickupPhotoUrl;
  final String? qrCode;
  final DateTime? claimedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final String? deliveryNotes;
  final int? rating;
  final String? feedback;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get weightKg => items.fold(0, (s, i) => s + i.weightKg);
  int get portions => items.length;
  String get description => items.map((i) => i.name).join(', ');
}
