// Pure Dart — zero Flutter or backend imports.

class RecentDelivery {
  const RecentDelivery({
    required this.batchId,
    required this.deliveredAt,
    required this.portions,
    this.donorName,
  });

  final String batchId;
  final DateTime deliveredAt;
  final int portions;
  final String? donorName;
}
