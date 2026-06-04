import 'package:hive_flutter/hive_flutter.dart';

// ── Read store (persists which notification IDs have been read) ────────────────

abstract interface class NotificationReadStore {
  Set<String> loadReadIds();
  void saveReadIds(Set<String> ids);
}

class HiveNotificationReadStore implements NotificationReadStore {
  static const _boxName = 'notification_prefs';
  static const _readKey = 'read_ids';

  @override
  Set<String> loadReadIds() {
    final raw = Hive.box<dynamic>(_boxName).get(_readKey);
    if (raw == null) return {};
    return Set<String>.from((raw as List).cast<String>());
  }

  @override
  void saveReadIds(Set<String> ids) =>
      Hive.box<dynamic>(_boxName).put(_readKey, ids.toList());
}

// ── Pref store (persists push notification enabled/disabled toggle) ────────────

abstract interface class NotificationPrefStore {
  bool load();
  Future<void> save(bool value);
}

class HiveNotificationPrefStore implements NotificationPrefStore {
  static const _boxName = 'notification_prefs';
  static const _pushKey = 'push_enabled';

  @override
  bool load() => (Hive.box<dynamic>(_boxName).get(_pushKey) as bool?) ?? false;

  @override
  Future<void> save(bool value) async =>
      Hive.box<dynamic>(_boxName).put(_pushKey, value);
}
