import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';

/// Plain Dart cache model for Hive serialisation of [RecentDelivery].
/// Stored as a JSON-encoded string in a `Hive<String>` box keyed by
/// `"${beneficiaryId}_page_${pageIndex}"`.
/// No Freezed / TypeAdapter — avoids additional codegen for a transient cache.
class RecentDeliveryCacheEntry {
  const RecentDeliveryCacheEntry({
    required this.batchId,
    required this.deliveredAtMs,
    required this.portions,
    this.donorName,
    this.category,
  });

  final String batchId;
  final int deliveredAtMs;
  final int portions;
  final String? donorName;
  final String? category;

  RecentDelivery toDomain() => RecentDelivery(
    batchId: batchId,
    deliveredAt: DateTime.fromMillisecondsSinceEpoch(deliveredAtMs),
    portions: portions,
    donorName: donorName,
    category: category,
  );

  Map<String, dynamic> toJson() => {
    'batchId': batchId,
    'deliveredAtMs': deliveredAtMs,
    'portions': portions,
    if (donorName != null) 'donorName': donorName,
    if (category != null) 'category': category,
  };

  factory RecentDeliveryCacheEntry.fromJson(Map<String, dynamic> json) =>
      RecentDeliveryCacheEntry(
        batchId: json['batchId'] as String,
        deliveredAtMs: json['deliveredAtMs'] as int,
        portions: json['portions'] as int,
        donorName: json['donorName'] as String?,
        category: json['category'] as String?,
      );
}
