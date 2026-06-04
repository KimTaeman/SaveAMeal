import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';

/// Returned by [FetchDeliveryHistoryPageUseCase].
/// [nextCursor] is an opaque handle (a Firestore DocumentSnapshot in practice)
/// kept as Object? so the domain layer holds no Firestore reference types.
class DeliveryHistoryPage {
  const DeliveryHistoryPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<RecentDelivery> items;
  final bool hasMore;
  final Object? nextCursor;
}
