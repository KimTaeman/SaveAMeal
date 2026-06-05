// Pure Dart interface — no Flutter or backend imports.
import 'package:saveameal/core/models/batch_item_model.dart';
import 'package:saveameal/shared/domain/entities/batch_status.dart';

class BatchSummary {
  const BatchSummary({
    required this.id,
    required this.donorName,
    required this.pickupAddress,
    required this.beneficiaryAddress,
    required this.beneficiaryName,
    required this.totalPortions,
    required this.lat,
    required this.lng,
    required this.foodCategory,
    required this.status,
    this.beneficiaryLat,
    this.beneficiaryLng,
    this.pickupWindowStart,
    this.pickupWindowEnd,
    this.specialInstructions,
    this.items = const [],
  });

  final String id;
  final String donorName;
  final String pickupAddress;
  final String beneficiaryAddress;
  final String beneficiaryName;
  final int totalPortions;
  final double lat;
  final double lng;
  final double? beneficiaryLat;
  final double? beneficiaryLng;
  final String foodCategory;
  final BatchStatus status;
  final String? pickupWindowStart;
  final String? pickupWindowEnd;
  final String? specialInstructions;
  final List<BatchItemModel> items;
}

abstract class DriverRepository {
  Stream<List<BatchSummary>> getOpenBatches();
  Stream<BatchSummary?> getActiveBatch(String driverId);
  Future<void> claimBatch(String batchId, String driverId);
  Future<void> confirmPickup(String batchId, String photoUrl);
  Future<void> confirmDelivery(String batchId, String? notes);
  Future<void> upsertLocation(String driverId, double lat, double lng);
  Future<void> deleteLocation(String driverId);
  Future<void> updateBatchEta(String batchId, int eta);
  Stream<int> watchPoints(String uid);
}
