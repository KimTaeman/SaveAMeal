import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';

abstract interface class NotificationsRepository {
  List<AppNotification> getAll();
  void markRead(String id);
  void markAllRead();
}
