import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/notifications/data/repositories/mock_notifications_repository.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/domain/repositories/notifications_repository.dart';

part 'notifications_provider.g.dart';

@riverpod
NotificationsRepository notificationsRepository(Ref ref) =>
    MockNotificationsRepository();

@riverpod
class NotificationsNotifier extends _$NotificationsNotifier {
  @override
  List<AppNotification> build() =>
      ref.read(notificationsRepositoryProvider).getAll();

  void markRead(String id) {
    ref.read(notificationsRepositoryProvider).markRead(id);
    state = ref.read(notificationsRepositoryProvider).getAll();
  }

  void markAllRead() {
    ref.read(notificationsRepositoryProvider).markAllRead();
    state = ref.read(notificationsRepositoryProvider).getAll();
  }
}
