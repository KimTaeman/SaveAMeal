// Pure Dart entity — no Flutter or backend imports.

enum BatchStatus { open, claimed, pickedUp, delivered, closed }

class Batch {
  const Batch({
    required this.id,
    required this.donorId,
    required this.description,
    required this.weightKg,
    required this.portions,
    required this.pickupAddress,
    required this.status,
    this.driverId,
    this.beneficiaryId,
    this.photoUrl,
    this.qrCode,
    this.rating,
    this.feedback,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String donorId;
  final String description;
  final double weightKg;
  final int portions;
  final String pickupAddress;
  final BatchStatus status;
  final String? driverId;
  final String? beneficiaryId;
  final String? photoUrl;
  final String? qrCode;
  final int? rating;
  final String? feedback;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
