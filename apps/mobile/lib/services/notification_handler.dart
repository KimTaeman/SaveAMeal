import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/core/logging/app_logger.dart';

class NotificationHandler {
  NotificationHandler(this._router);

  final GoRouter _router;

  List<StreamSubscription<RemoteMessage>> init() {
    final subs = <StreamSubscription<RemoteMessage>>[];

    // Foreground: app is open and visible.
    // Firestore real-time streams already update the UI, so we just log.
    subs.add(
      FirebaseMessaging.onMessage.listen((message) {
        AppLogger.info(
          'FCM foreground: ${message.notification?.title} '
          '(type=${message.data["type"]})',
        );
      }),
    );

    // Background tap: app was minimized, user tapped the system notification.
    subs.add(FirebaseMessaging.onMessageOpenedApp.listen(_navigate));

    // Terminated tap: app was closed, user tapped to open it.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _navigate(message);
    });

    return subs;
  }

  void _navigate(RemoteMessage message) {
    final route = routeForType(message.data['type'] as String?);
    if (route != null) _router.go(route);
  }

  /// Maps a notification `data.type` value to a GoRouter path.
  /// Returns `null` for unknown or missing types (no navigation).
  static String? routeForType(String? type) {
    switch (type) {
      case 'new_batch':
        return '/driver';
      case 'driver_assigned':
        return '/donor';
      case 'incoming_delivery':
      case 'delivery_arrived':
        return '/beneficiary';
      default:
        return null;
    }
  }
}
