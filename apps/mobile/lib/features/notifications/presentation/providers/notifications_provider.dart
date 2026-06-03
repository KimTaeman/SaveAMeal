import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/notifications/data/mock_notifications_repository.dart';
import 'package:saveameal/features/notifications/data/notification_prefs_store.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/domain/repositories/notifications_repository.dart';

part 'notifications_provider.g.dart';

// Types the donor sees in their notification centre.
const _kDonorTypes = {
  NotificationType.matchConfirmed,
  NotificationType.driverAssigned,
  NotificationType.deliverySuccessful,
  NotificationType.batchCompleted,
};

@riverpod
NotificationsRepository notificationsRepository(Ref ref) =>
    MockNotificationsRepository();

@riverpod
NotificationReadStore notificationReadStore(Ref ref) =>
    HiveNotificationReadStore();

@riverpod
class NotificationsNotifier extends _$NotificationsNotifier {
  @override
  List<AppNotification> build() {
    final role = ref.watch(authStateProvider).asData?.value?.role;
    final readStore = ref.watch(notificationReadStoreProvider);
    final readIds = readStore.loadReadIds();
    final all = ref.watch(notificationsRepositoryProvider).getAll();

    final filtered = role == UserRole.donor
        ? all.where((n) => _kDonorTypes.contains(n.type)).toList()
        : all;

    return filtered
        .map((n) => readIds.contains(n.id) ? n.copyWith(isRead: true) : n)
        .toList();
  }

  void markRead(String id) {
    final store = ref.read(notificationReadStoreProvider);
    store.saveReadIds({...store.loadReadIds(), id});
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
  }

  void markAllRead() {
    final store = ref.read(notificationReadStoreProvider);
    store.saveReadIds(state.map((n) => n.id).toSet());
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }
}
