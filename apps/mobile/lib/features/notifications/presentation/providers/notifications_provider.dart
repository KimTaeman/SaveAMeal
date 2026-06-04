import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/notifications/data/notification_prefs_store.dart';
import 'package:saveameal/features/notifications/data/repositories/firestore_notifications_repository.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/domain/repositories/notifications_repository.dart';

part 'notifications_provider.g.dart';

const _kDonorTypes = {
  NotificationType.matchConfirmed,
  NotificationType.driverAssigned,
  NotificationType.deliverySuccessful,
  NotificationType.batchCompleted,
};

@riverpod
NotificationsRepository notificationsRepository(Ref ref) =>
    FirestoreNotificationsRepository(FirebaseFirestore.instance);

@riverpod
NotificationReadStore notificationReadStore(Ref ref) =>
    HiveNotificationReadStore();

@riverpod
Stream<List<AppNotification>> notificationsStream(Ref ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(notificationsRepositoryProvider).watchAll(uid);
}

@riverpod
class NotificationsNotifier extends _$NotificationsNotifier {
  @override
  List<AppNotification> build() {
    final role = ref.watch(authStateProvider).asData?.value?.role;
    final readStore = ref.watch(notificationReadStoreProvider);
    final readIds = readStore.loadReadIds();
    final all = ref.watch(notificationsStreamProvider).asData?.value ?? [];

    final filtered = role == UserRole.donor
        ? all.where((n) => _kDonorTypes.contains(n.type)).toList()
        : all;

    return filtered
        .map((n) => readIds.contains(n.id) ? n.copyWith(isRead: true) : n)
        .toList();
  }

  Future<void> markRead(String id) async {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) return;
    final store = ref.read(notificationReadStoreProvider);
    store.saveReadIds({...store.loadReadIds(), id});
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    await ref.read(notificationsRepositoryProvider).markRead(uid, id);
  }

  Future<void> markAllRead() async {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) return;
    final store = ref.read(notificationReadStoreProvider);
    store.saveReadIds(state.map((n) => n.id).toSet());
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    await ref.read(notificationsRepositoryProvider).markAllRead(uid);
  }
}
