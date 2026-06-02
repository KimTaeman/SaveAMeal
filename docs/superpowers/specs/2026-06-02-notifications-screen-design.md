# Notifications Screen — Design Spec

**Date:** 2026-06-02  
**Status:** Approved  
**Approach:** Clean Architecture stubs (mock data, Firestore-ready)

---

## 1. Overview

A shared `/notifications` screen accessible from all three role dashboards (donor, driver, beneficiary). Displays a date-grouped list of in-app notifications with unread indicators and mark-as-read actions. The data layer is stubbed with mock data; swapping in a Firestore datasource requires changing one file.

---

## 2. File Layout

```
features/notifications/
  domain/
    entities/app_notification.dart
    repositories/notifications_repository.dart
  data/
    repositories/mock_notifications_repository.dart
  presentation/
    providers/notifications_provider.dart
    providers/notifications_provider.g.dart   ← generated, do not edit
    screens/notifications_screen.dart

test/
  widget/
    notifications_screen_test.dart
```

---

## 3. Domain Layer

### `AppNotification` entity

Pure Dart, Freezed, no Flutter or backend imports.

```dart
enum NotificationType {
  newBatch,
  driverAssigned,
  deliveryArriving,
  deliverySuccessful,
  batchCompleted,
  matchConfirmed,
}

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required NotificationType type,
    required String title,
    required String body,
    required DateTime timestamp,
    required bool isRead,
    String? actionLabel,   // e.g. "View Receipt"
    String? actionBatchId, // e.g. "8832" — drives deep-link on tap
  }) = _AppNotification;
}
```

### `NotificationsRepository` interface

```dart
abstract interface class NotificationsRepository {
  List<AppNotification> getAll();
  void markRead(String id);
  void markAllRead();
}
```

---

## 4. Data Layer

### `MockNotificationsRepository`

Implements `NotificationsRepository`. Holds a mutable in-memory `List<AppNotification>` seeded with ~5 items covering all Figma states:

| # | Type | Day | Read | Has action card |
|---|------|-----|------|----------------|
| 1 | `deliveryArriving` | Today | false | no |
| 2 | `deliverySuccessful` | Yesterday | true | yes ("View Receipt", batchId: "8832") |
| 3 | `matchConfirmed` | Today | false | no |
| 4 | `deliverySuccessful` | Today | true | no |
| 5 | `batchCompleted` | Yesterday | true | no |

`markRead` and `markAllRead` mutate the in-memory list and return void. No async needed at this layer.

---

## 5. Presentation Layer

### `NotificationsProvider` (Riverpod notifier)

```dart
@riverpod
class NotificationsNotifier extends _$NotificationsNotifier {
  List<AppNotification> build() => ref.read(notificationsRepositoryProvider).getAll();

  void markRead(String id) {
    ref.read(notificationsRepositoryProvider).markRead(id);
    state = ref.read(notificationsRepositoryProvider).getAll();
  }

  void markAllRead() {
    ref.read(notificationsRepositoryProvider).markAllRead();
    state = ref.read(notificationsRepositoryProvider).getAll();
  }
}

@riverpod
NotificationsRepository notificationsRepository(Ref ref) =>
    MockNotificationsRepository();
```

State type: `List<AppNotification>` — no `AsyncValue` until Firestore is wired.

### `NotificationsScreen`

- `Scaffold` with `AppBar`:
  - Leading: back arrow (`context.pop()`)
  - Title: "Notifications"
  - Action: "Mark all read" `TextButton` — calls `notifier.markAllRead()`
- Body: `ListView` of date-group sections
  - Grouping logic: compare each notification's date to `DateTime.now()` — "TODAY" if same calendar day, "YESTERDAY" if one day prior, otherwise formatted date
  - Section header: `"TODAY (N)"` / `"YESTERDAY (N)"` — grey caps text with horizontal rule
  - Empty state: centered "No notifications" text when list is empty

### Notification card

White rounded `Container` (radius 12, subtle shadow) with:
- **Icon circle** (40×40): type-specific `Icons.*`, `cs.primary` background if unread, `cs.surfaceVariant` if read
- **Unread dot**: 8px green dot (`ac.success`) at top-right of icon circle, hidden when `isRead`
- **Title**: `textTheme.bodyMedium` bold if unread, normal weight if read
- **Body**: `textTheme.bodySmall`, `cs.onSurfaceVariant`
- **Timestamp**: relative string — "Nm ago" for <60 min, "Nh ago" for <24 h, "yesterday at HH:mm" otherwise; `textTheme.labelSmall`
- **Action card** (optional, `deliverySuccessful` type with `actionBatchId`): tappable `InkWell` row with placeholder image (`Icons.receipt_long`), `actionLabel`, and "Order #`actionBatchId`" subtitle

### Icon mapping

| `NotificationType` | Icon |
|--------------------|------|
| `newBatch` | `Icons.local_shipping_outlined` |
| `driverAssigned` | `Icons.directions_car_outlined` |
| `deliveryArriving` | `Icons.access_time_outlined` |
| `deliverySuccessful` | `Icons.check_circle_outline` |
| `batchCompleted` | `Icons.check_circle_outline` |
| `matchConfirmed` | `Icons.handshake_outlined` |

### Tap behaviour

1. Call `notifier.markRead(notification.id)`
2. If `actionBatchId != null`: navigate to the appropriate deep-link (donor → `/donor/batch/:id/qr`, beneficiary → `/beneficiary/delivery/:id`) — role determined from the notification type
3. Otherwise: no further navigation (mark-read in place)

---

## 6. Routing

Add to `app/router.dart` at root level alongside existing role routes:

```dart
GoRoute(
  path: '/notifications',
  builder: (context, state) => const NotificationsScreen(),
),
```

Auth redirect already covers all root-level routes via the existing `_AuthChangeNotifier` redirect logic — no additional guard needed.

### Dashboard wiring

Replace `onPressed: null` with `onPressed: () => context.push('/notifications')` in:
- `donor_dashboard_screen.dart` — `_DashboardHeader`
- `beneficiary_dashboard_screen.dart` — AppBar actions
- `driver_map_screen.dart` — AppBar actions
- `claim_rescue_screen.dart` — AppBar actions

---

## 7. Testing

### `notifications_screen_test.dart` (widget tests)

**Test 1 — renders correctly**
- Override `notificationsRepositoryProvider` with mock returning seeded data
- Assert: "TODAY (3)" and "YESTERDAY (2)" section headers present
- Assert: unread dot visible on unread cards, hidden on read cards

**Test 2 — mark all read**
- Tap "Mark all read" button
- Assert: all unread dots are gone

---

## 8. Firestore Swap Path

When the backend is decided, the only change needed is:
1. Add `FirestoreNotificationsRepository` implementing `NotificationsRepository`
2. Change `notificationsRepositoryProvider` to return `FirestoreNotificationsRepository(ref.read(firestoreServiceProvider))`

The domain entity, provider notifier, and screen are unchanged.
