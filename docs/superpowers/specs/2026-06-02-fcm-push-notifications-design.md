# FCM Push Notifications — Design Spec
**Date:** 2026-06-02
**Feature:** Full-stack Firebase Cloud Messaging for SaveAMeal
**Approach:** FCM Topics for driver broadcast + Cloud Functions v2 Firestore triggers

---

## 1. Scope

Implement the three notification events specified in the architecture document:

| Event | Who gets notified | Message |
|---|---|---|
| New batch posted | All drivers (FCM topic) | "New pickup available" |
| Batch claimed by driver | Donor + Beneficiary (individual tokens) | "Driver is on the way" / "Delivery incoming" |
| Delivery marked complete | Beneficiary (individual token) | "Food has arrived — tap to confirm receipt" |

Also implements as part of `onDeliveryComplete`: atomic `impactMetrics` increment (totalKg, totalMeals, totalCo2e) for donor and global documents.

**Out of scope for this task:**
- ETA calculation (location broadcasting is a separate task)
- Geo-filtered driver notifications (broadcast to all drivers)
- `cleanupLocations` Cloud Function
- iOS APNs certificate setup (documented as a manual step)

---

## 2. Architecture Overview

```
Flutter App                    Firestore                    Cloud Functions
──────────────────────────────────────────────────────────────────────────
Login/Register
  └─ FcmService.requestPermission()
  └─ FcmService.getToken() → save to users/{uid}.fcmToken
  └─ drivers: subscribeToTopic('new_batch_available')

Donor creates batch ──────────► batches/{id} (status:open) ──► onBatchCreated
                                                                  └─ topic msg → all drivers
                                                                     type: "new_batch"

Driver accepts ───────────────► batches/{id} (status:claimed) ─► onBatchClaimed
                                                                  └─ token msg → donor
                                                                     type: "driver_assigned"
                                                                  └─ token msg → beneficiary
                                                                     type: "incoming_delivery"

Driver marks delivered ───────► batches/{id} (status:delivered)─► onDeliveryComplete
                                                                  └─ token msg → beneficiary
                                                                     type: "delivery_arrived"
                                                                  └─ FieldValue.increment
                                                                     → impactMetrics/{donorId}
                                                                     → impactMetrics/global
```

---

## 3. Flutter Client

### 3.1 New File: `services/fcm_service.dart`

```dart
class FcmService {
  FcmService(this._messaging);
  final FirebaseMessaging _messaging;

  Future<void> requestPermission();
  // Requests notification permission (required on iOS; no-op on Android <13,
  // prompts on Android 13+). Called once after login.

  Future<String?> getToken();
  // Returns the FCM registration token for this device installation.
  // Returns null if permission was denied.

  Future<void> subscribeToTopic(String topic);
  // Used by driver role: subscribeToTopic('new_batch_available')

  Future<void> unsubscribeFromTopic(String topic);
  // Called on logout for driver role.
}
```

### 3.2 New File: `services/notification_handler.dart`

```dart
class NotificationHandler {
  NotificationHandler(this._router);
  final GoRouter _router;

  void init();
  // Sets up three listeners. Called once from App.initState().
  // - FirebaseMessaging.onMessage        → foreground: show SnackBar banner
  // - FirebaseMessaging.onMessageOpenedApp → background tap: route
  // - FirebaseMessaging.instance.getInitialMessage() → terminated tap: route
}
```

**Background handler** — top-level function, registered in `main.dart` before `runApp`:

```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage msg) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // No UI action — system tray already shows the notification.
}
```

### 3.3 Deep-Link Routing

`NotificationHandler._routeFromMessage` reads `message.data['type']` and navigates:

| `type` | Route |
|---|---|
| `new_batch` | `/driver` |
| `driver_assigned` | `/donor` |
| `incoming_delivery` | `/beneficiary` |
| `delivery_arrived` | `/beneficiary` |

Unknown or missing `type` values are ignored silently.

### 3.4 Modified: `core/models/user_model.dart`

Add one nullable field to the Freezed class:

```dart
String? fcmToken,
```

Requires `dart run build_runner build` to regenerate `.g.dart` / `.freezed.dart`.

### 3.5 Modified: `services/firestore_service.dart`

Add one method:

```dart
Future<void> updateFcmToken(String uid, String token) =>
    _db.collection(FirestoreConstants.users).doc(uid).update({'fcmToken': token});
```

### 3.6 Modified: `features/auth/data/datasources/auth_remote_datasource.dart`

`AuthRemoteDatasourceImpl` gets `FcmService` injected as a third constructor parameter. After every successful `signIn` and `signUp`:

```
1. await FcmService.requestPermission()
2. token = await FcmService.getToken()
3. if token != null: await FirestoreService.updateFcmToken(uid, token)
4. if role == UserRole.driver: await FcmService.subscribeToTopic('new_batch_available')
```

On `signOut`:
```
await FcmService.unsubscribeFromTopic('new_batch_available')
// Always called regardless of role — FCM silently ignores unsubscribe
// calls for topics the device was never subscribed to.
```

### 3.7 Modified: `services/service_providers.dart`

Add provider for `FcmService`:

```dart
@riverpod
FcmService fcmService(Ref ref) =>
    FcmService(FirebaseMessaging.instance);
```

Update `authDatasourceProvider` to pass `ref.watch(fcmServiceProvider)` as the third argument.

### 3.8 Modified: `app/app.dart`

`App` becomes a `ConsumerStatefulWidget`. In `initState`:

```dart
final router = ref.read(routerProvider);
NotificationHandler(router).init();
```

### 3.9 Modified: `main.dart`

Register background handler before `runApp`:

```dart
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

---

## 4. Cloud Functions

### 4.1 Directory Structure

```
functions/           ← new directory at repo root
  package.json
  tsconfig.json
  src/
    index.ts         ← re-exports all three functions
    onBatchCreated.ts
    onBatchClaimed.ts
    onDeliveryComplete.ts
```

### 4.2 `package.json` Dependencies

```json
{
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^6.0.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@types/node": "^20.0.0"
  }
}
```

### 4.3 `onBatchCreated.ts`

**Trigger:** `onDocumentCreated('batches/{batchId}')`

```
reads:  batch data — donorName, items[0].name, sum(items[].weightKg)
sends:  FCM topic message → topic: "new_batch_available"
        notification: { title: "New pickup available",
                        body: "{donorName} · {totalKg} kg" }
        data:          { type: "new_batch", batchId }
```

### 4.4 `onBatchClaimed.ts`

**Trigger:** `onDocumentUpdated('batches/{batchId}')`

**Guard:** `before.status !== 'claimed' && after.status === 'claimed'`

```
reads:  users/{after.donorId}.fcmToken        → send if present
        users/{after.beneficiaryId}.fcmToken  → send if present

→ donor notification:
  title: "Driver is on the way"
  body:  "Your batch is being picked up"
  data:  { type: "driver_assigned", batchId }

→ beneficiary notification:
  title: "Delivery incoming"
  body:  "{totalKg} kg from {donorName}"   (totalKg = sum of items[].weightKg)
  data:  { type: "incoming_delivery", batchId }
```

Missing or null tokens are skipped with a `logger.warn` — no crash or retry.

### 4.5 `onDeliveryComplete.ts`

**Trigger:** `onDocumentUpdated('batches/{batchId}')`

**Guard:** `before.status !== 'delivered' && after.status === 'delivered'`

```
reads:  users/{after.beneficiaryId}.fcmToken  → send if present
        after.items[]  → calculate totals

→ beneficiary notification:
  title: "Food has arrived"
  body:  "Tap to confirm receipt"
  data:  { type: "delivery_arrived", batchId }

→ impactMetrics/{after.donorId}  FieldValue.increment:
    totalKg:    sum(items[].weightKg)
    totalMeals: totalKg * 2.5
    totalCo2e:  totalKg * 2.5

→ impactMetrics/global  same increments

formulas (BatchItemModel stores weightKg only — no portions unit):
  totalKg    = items.reduce((sum, i) => sum + i.weightKg, 0)
  totalMeals = totalKg * 2.5   (industry standard: 1 kg ≈ 2.5 meals)
  totalCo2e  = totalKg * 2.5   (industry standard: 1 kg food waste ≈ 2.5 kg CO₂e)
```

---

## 5. Notification Payload Schema

All notifications follow this structure so the Flutter handler can route them:

```json
{
  "notification": {
    "title": "...",
    "body": "..."
  },
  "data": {
    "type": "new_batch | driver_assigned | incoming_delivery | delivery_arrived",
    "batchId": "<firestoreDocId>"
  }
}
```

---

## 6. Error Handling

| Scenario | Behaviour |
|---|---|
| User denies notification permission | `getToken()` returns null; token write is skipped; user never receives push but app works normally |
| FCM token missing from Firestore | Cloud Function logs a warning and skips that send; no crash |
| `beneficiaryId` not set on batch at claim time | `onBatchClaimed` skips beneficiary notification with a warning |
| Cloud Function cold-start / timeout | Firebase retries trigger automatically (gen-2 default) |
| `sendMessage` FCM error (invalid token) | Log and continue; token will refresh naturally on next login |

---

## 7. Manual Setup Steps (not automated)

These require console/CLI actions outside the codebase:

1. **iOS APNs**: Upload APNs Auth Key in Firebase Console → Project Settings → Cloud Messaging → iOS app. Without this, iOS devices receive no push.
2. **Firebase project billing**: Cloud Functions require the Blaze (pay-as-you-go) plan. Free Spark plan blocks function deployment.
3. **Deploy functions**: `cd functions && npm install && firebase deploy --only functions`
4. **Android `google-services.json`**: Already present. No change needed.
5. **iOS `GoogleService-Info.plist`**: Already present. No change needed.

---

## 8. Files Changed Summary

| File | Change |
|---|---|
| `services/fcm_service.dart` | **New** |
| `services/notification_handler.dart` | **New** |
| `functions/` (entire directory) | **New** |
| `core/models/user_model.dart` | Add `fcmToken` field |
| `core/models/user_model.freezed.dart` | Regenerated |
| `core/models/user_model.g.dart` | Regenerated |
| `services/firestore_service.dart` | Add `updateFcmToken` method |
| `services/service_providers.dart` | Add `fcmServiceProvider`, update `authDatasourceProvider` |
| `features/auth/data/datasources/auth_remote_datasource.dart` | Inject `FcmService`, call token registration after login/signup, unsubscribe on logout |
| `app/app.dart` | Convert to `ConsumerStatefulWidget`, init `NotificationHandler` |
| `main.dart` | Register `_firebaseMessagingBackgroundHandler` |
