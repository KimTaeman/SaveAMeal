import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';

abstract interface class NotificationsRepository {
  Stream<List<AppNotification>> watchAll(String uid);
  Future<void> markRead(String uid, String id);
  Future<void> markAllRead(String uid);
}
