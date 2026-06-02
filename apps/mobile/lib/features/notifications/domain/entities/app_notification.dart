import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';

enum NotificationType {
  newBatch,
  driverAssigned,
  deliveryArriving,
  deliverySuccessful,
  batchCompleted,
  matchConfirmed,
}

@freezed
sealed class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required NotificationType type,
    required String title,
    required String body,
    required DateTime timestamp,
    required bool isRead,
    String? actionLabel,
    String? actionBatchId,
  }) = _AppNotification;
}
