import 'package:saveameal/features/beneficiary/domain/entities/order_history_entry.dart';

/// Plain Dart DTO for a single order history entry.
/// Constructed from raw Firestore maps by the datasource.
class OrderHistoryEntryModel {
  const OrderHistoryEntryModel({
    required this.id,
    required this.displayId,
    required this.status,
    required this.itemDescription,
    required this.donorName,
    required this.totalWeightKg,
    this.date,
    this.foodCategory,
  });

  final String id;
  final String displayId;
  final String status; // raw Firestore status string
  final String itemDescription;
  final String donorName;
  final double totalWeightKg;
  final DateTime? date;
  final String? foodCategory;

  OrderHistoryEntry toDomain() => throw UnimplementedError();
}
