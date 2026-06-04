# Firestore-backed In-App Notifications

**Date:** 2026-06-05
**Status:** Approved

## Problem

The `NotificationsScreen` reads from `MockNotificationsRepository` (hardcoded seed data). Real FCM messages are delivered as device banners but never appear in the in-app notification list. Notifications must survive device reinstalls and system tray clears.

## Solution

Cloud Functions write a Firestore notification document alongside every FCM send. The Flutter app streams from that collection and displays it in the existing `NotificationsScreen`.

---

## Firestore Schema

Collection path: `notifications/{userId}/items/{notificationId}`

| Field | Type | Notes |
|---|---|---|
| `type` | String | `new_batch` \| `driver_assigned` \| `incoming_delivery` \| `delivery_arrived` |
| `title` | String | Notification title |
| `body` | String | Notification body |
| `timestamp` | Timestamp | Server time |
| `isRead` | bool | Default `false` |
| `actionLabel` | String? | e.g. "View Receipt" |
| `actionBatchId` | String? | Links to batch screen |

Security rules: users may only read/write `notifications/{userId}` where `userId == request.auth.uid`.

---

## Cloud Functions Changes

### `onBatchCreated.ts`
- Query all users where `role == 'driver'`
- For each driver: write a `new_batch` notification doc to `notifications/{driverId}/items/{id}`
- Runs after FCM topic send

### `onBatchClaimed.ts`
- Write a `driver_assigned` notification to `notifications/{donorId}/items/{id}`
- Runs after FCM token send to donor

### `onDeliveryComplete.ts`
- Write a `delivery_arrived` notification to `notifications/{beneficiaryId}/items/{id}`
- Runs after FCM token send to beneficiary

---

## Flutter Changes

### 1. `NotificationsRepository` interface
Add `Stream<List<AppNotification>> watchAll()` alongside existing `markRead` and `markAllRead`.

### 2. `FirestoreNotificationsRepository`
New implementation in `features/notifications/data/repositories/`:
- `watchAll()` — streams `notifications/{uid}/items` ordered by timestamp desc, maps Firestore docs to `AppNotification`
- `markRead(id)` — updates `isRead: true` on the doc
- `markAllRead()` — batch-writes `isRead: true` on all items

### 3. `notificationsRepositoryProvider`
Swap `MockNotificationsRepository` for `FirestoreNotificationsRepository`.

### 4. `NotificationsNotifier`
Change `build()` to consume the stream from `watchAll()` using `AsyncNotifier` pattern.

### 5. `FirestoreConstants`
Add `notifications` collection constant.

---

## What Does NOT Change

- `NotificationsScreen` UI — no changes
- `AppNotification` entity — no changes
- `NotificationHandler` routing — no changes

---

## Testing

- Unit test `FirestoreNotificationsRepository` with a fake Firestore
- Update `notifications_screen_test.dart` to override the new stream-based provider
- Cloud Functions: add unit tests for the Firestore write alongside existing FCM tests
