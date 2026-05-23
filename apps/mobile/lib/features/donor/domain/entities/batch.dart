import 'package:saveameal/features/donor/domain/entities/batch_item.dart';

enum BatchStatus { open, claimed, pickedUp, delivered, closed }

class Batch {
  const Batch({
    required this.id,
    required this.donorId,
    required this.items,
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
  final List<BatchItem> items;
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

  double get weightKg => items.fold(0, (s, i) => s + i.weightKg);
  int get portions => items.length;
  String get description => items.map((i) => i.name).join(', ');
}
