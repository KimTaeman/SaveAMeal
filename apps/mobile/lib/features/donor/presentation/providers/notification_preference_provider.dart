import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/notifications/data/notification_prefs_store.dart';
import 'package:saveameal/services/service_providers.dart';

part 'notification_preference_provider.g.dart';

const _kDonorTopic = 'donor_updates';

@riverpod
NotificationPrefStore notificationPrefStore(Ref ref) =>
    HiveNotificationPrefStore();

@riverpod
class NotificationPreferenceNotifier extends _$NotificationPreferenceNotifier {
  @override
  bool build() => ref.watch(notificationPrefStoreProvider).load();

  Future<void> enable(String uid) async {
    final fcm = ref.read(fcmServiceProvider);
    final firestore = ref.read(firestoreServiceProvider);
    final store = ref.read(notificationPrefStoreProvider);

    await fcm.requestPermission();
    await fcm.subscribeToTopic(_kDonorTopic);
    final token = await fcm.getToken();
    if (token != null) {
      await firestore.updateFcmToken(uid, token);
    }
    await store.save(true);
    state = true;
  }

  Future<void> disable(String uid) async {
    final fcm = ref.read(fcmServiceProvider);
    final firestore = ref.read(firestoreServiceProvider);
    final store = ref.read(notificationPrefStoreProvider);

    await fcm.unsubscribeFromTopic(_kDonorTopic);
    await firestore.updateUser(uid, {'fcmToken': null});
    await store.save(false);
    state = false;
  }
}
