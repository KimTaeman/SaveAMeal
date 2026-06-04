// Pure Dart entity — zero Flutter or backend imports.

enum OrderHistoryEntryStatus { inTransit, delivered, closed }

class OrderHistoryEntry {
  const OrderHistoryEntry({
    required this.id,
    required this.displayId,
    required this.status,
    required this.itemDescription,
    required this.donorName,
    required this.totalWeightKg,
    this.date,
    this.foodCategory,
  });

  final String id; // Firestore batch document ID
  final String displayId; // 'SH-' + id.substring(id.length - 4).toUpperCase()
  final OrderHistoryEntryStatus status; // inTransit | delivered | closed
  final String itemDescription; // first item name, or comma-joined item names
  final String donorName; // from BatchModel.donorName (denormalised)
  final double
  totalWeightKg; // sum of item.weightKg across all items in the batch
  final DateTime? date; // from BatchModel.deliveredAt
  final String?
  foodCategory; // first item category — drives icon selection in OrderHistoryCard
}
