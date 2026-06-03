// Pure Dart — zero Flutter or backend imports.

class RecentDelivery {
  const RecentDelivery({
    required this.batchId,
    required this.deliveredAt,
    required this.portions,
    this.donorName,
    this.category,
  });

  final String batchId;
  final DateTime deliveredAt;
  final int portions;
  final String? donorName;

  /// First item category from BatchItemModel; null for legacy rows.
  /// Nullable for backwards compatibility — existing callers ignore this field.
  // TODO(future): use majority-category approach for mixed-category batches.
  final String? category;
}
