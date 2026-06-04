import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final user = ref.watch(authStateProvider).asData?.value;
    final uid = user?.uid ?? '';
    final role = user?.role;
    final readStore = ref.watch(notificationReadStoreProvider);
    final readIds = readStore.loadReadIds();
    final repo = ref.watch(notificationsRepositoryProvider);

    // Subscribe to the stream; seed with empty list until first event arrives.
    final all = ref.watch(
      StreamProvider.autoDispose<List<AppNotification>>(
        (ref) => repo.watchAll(uid),
      ).select((snap) => snap.asData?.value ?? const []),
    );

    final filtered = role == UserRole.donor
        ? all.where((n) => _kDonorTypes.contains(n.type)).toList()
        : all;

    return filtered
        .map((n) => readIds.contains(n.id) ? n.copyWith(isRead: true) : n)
        .toList();
  }

  void markRead(String id) {
    final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
    final store = ref.read(notificationReadStoreProvider);
    store.saveReadIds({...store.loadReadIds(), id});
    ref.read(notificationsRepositoryProvider).markRead(uid, id);
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
  }

  void markAllRead() {
    final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
    final store = ref.read(notificationReadStoreProvider);
    store.saveReadIds(state.map((n) => n.id).toSet());
    ref.read(notificationsRepositoryProvider).markAllRead(uid);
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }
}
