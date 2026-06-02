# Live Driver Location Broadcasting — Design Spec
**Date:** 2026-06-02
**Feature:** Live driver location broadcasting + beneficiary tracking map

---

## 1. Scope

Three gaps closed by this feature:

| Gap | What's missing |
|---|---|
| Driver permissions | `_startTracking` calls `Geolocator.getCurrentPosition` without requesting permission — silently fails on fresh installs |
| Location doc cleanup | `_stopTracking` cancels the timer but never deletes `driverLocations/{driverId}` — stale doc remains in Firestore |
| TrackingScreen | `tracking_screen.dart` is a TODO stub — beneficiary sees "TODO: TrackingScreen" instead of a live map |

**Out of scope:** ETA calculation, `cleanupLocations` Cloud Function, `LocationService` stub replacement (DriverNotifier already bypasses it with direct `Geolocator` calls and that pattern is fine).

---

## 2. Architecture

```
Driver side                         Firestore                    Beneficiary side
──────────────────────────────────────────────────────────────────────────────────
DriverNotifier._startTracking()
  └─ Geolocator.checkPermission()
  └─ Geolocator.requestPermission()  (if needed)
  └─ if denied → log + return early
  └─ Timer.periodic(30s)
       └─ Geolocator.getCurrentPosition()
       └─ repository.upsertLocation()  ──────────────► driverLocations/{driverId}
                                                              │
DriverNotifier._stopTracking()                                │
  └─ cancel timer                                             │  (real-time listener)
  └─ repository.deleteLocation()  ────────────────────────────┘
       └─ FirestoreService.deleteDriverLocation()     TrackingScreen
                                                        └─ watchDriverLocation(driverId)
                                                             → driver pin (moves)
                                                        └─ getUser(beneficiaryId).lat/lng
                                                             → shelter pin (fixed)
```

---

## 3. Data Changes

### 3.1 `BeneficiaryModel`

Add two nullable fields to `apps/mobile/lib/core/models/beneficiary_model.dart`:

```dart
@freezed
sealed class BeneficiaryModel with _$BeneficiaryModel {
  const factory BeneficiaryModel({
    required String id,
    required String name,
    String? address,
    double? lat,   // ← new
    double? lng,   // ← new
  }) = _BeneficiaryModel;

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) =>
      _$BeneficiaryModelFromJson(json);
}
```

Requires `dart run build_runner build --delete-conflicting-outputs`.

### 3.2 `FirestoreService`

Add one method to `apps/mobile/lib/services/firestore_service.dart`:

```dart
Future<void> deleteDriverLocation(String driverId) =>
    _db.collection(FirestoreConstants.driverLocations).doc(driverId).delete();
```

### 3.3 `DriverRemoteDatasource` (abstract + impl)

Add to `apps/mobile/lib/features/driver/data/datasources/driver_remote_datasource.dart`:

```dart
// abstract:
Future<void> deleteLocation(String driverId);

// impl:
@override
Future<void> deleteLocation(String driverId) =>
    _firestore.deleteDriverLocation(driverId);
```

### 3.4 `DriverRepository` (abstract + impl)

Add to `apps/mobile/lib/features/driver/domain/repositories/driver_repository.dart`:

```dart
Future<void> deleteLocation(String driverId);
```

And to `apps/mobile/lib/features/driver/data/repositories/driver_repository_impl.dart`:

```dart
@override
Future<void> deleteLocation(String driverId) =>
    _datasource.deleteLocation(driverId);
```

---

## 4. DriverNotifier Changes

File: `apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart`

### 4.1 Add `_activeDriverId` field

```dart
String? _activeDriverId;
```

### 4.2 Replace `_startTracking`

```dart
Future<void> _startTracking(String driverId) async {
  _activeDriverId = driverId;

  // Request location permission before starting the timer.
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    AppLogger.warning('Location permission denied — tracking disabled');
    return;
  }

  _locationTimer?.cancel();
  _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await ref
          .read(driverRepositoryProvider)
          .upsertLocation(driverId, pos.latitude, pos.longitude);
    } on PermissionDeniedException {
      AppLogger.warning('Location permission denied — stopping tracking');
      _stopTracking();
    } catch (e) {
      AppLogger.warning('Location write failed', error: e);
    }
  });
}
```

Note: `_startTracking` becomes `async` — callers use `unawaited(_startTracking(driverId))` since the permission dialog is non-blocking from the claimBatch flow's perspective.

### 4.3 Replace `_stopTracking`

```dart
void _stopTracking() {
  _locationTimer?.cancel();
  _locationTimer = null;
  if (_activeDriverId != null) {
    ref
        .read(driverRepositoryProvider)
        .deleteLocation(_activeDriverId!)
        .catchError(
          (Object e) => AppLogger.warning('Location cleanup failed', error: e),
        );
    _activeDriverId = null;
  }
}
```

### 4.4 Update `claimBatch` call site

Change `_startTracking(driverId)` to `unawaited(_startTracking(driverId))`:

```dart
import 'dart:async' show unawaited;
// ...
unawaited(_startTracking(driverId));
```

---

## 5. TrackingScreen

File: `apps/mobile/lib/features/beneficiary/presentation/screens/tracking_screen.dart`

Replace the TODO stub entirely.

**Constructor:**

```dart
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({
    super.key,
    required this.driverId,
    required this.beneficiaryId,
  });

  final String driverId;
  final String beneficiaryId;
}
```

**State:**

```dart
class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  LatLng? _shelterLatLng;      // loaded once in initState
  GoogleMapController? _mapController;
}
```

The shelter lat/lng lives on `BeneficiaryModel` in the `beneficiaries` Firestore collection, not on `UserModel`.

**`FirestoreService.getBeneficiary`** — add to `firestore_service.dart`:

```dart
Future<BeneficiaryModel?> getBeneficiary(String beneficiaryId) async {
  final doc = await _db
      .collection(FirestoreConstants.beneficiaries)
      .doc(beneficiaryId)
      .get();
  if (!doc.exists || doc.data() == null) return null;
  return BeneficiaryModel.fromJson({...doc.data()!, 'id': doc.id});
}
```

**`initState`** — fetch beneficiary doc to get shelter coordinates:

```dart
@override
void initState() {
  super.initState();
  ref.read(firestoreServiceProvider)
      .getBeneficiary(widget.beneficiaryId)
      .then((ben) {
        if (!mounted) return;
        if (ben?.lat != null && ben?.lng != null) {
          setState(() => _shelterLatLng = LatLng(ben!.lat!, ben.lng!));
        }
      });
}
```

**`build` — map + status text:**

```dart
@override
Widget build(BuildContext context) {
  final driverLocation = ref.watch(
    driverLocationProvider(widget.driverId), // StreamProvider
  );

  return Scaffold(
    appBar: AppBar(title: const Text('Tracking Delivery')),
    body: Column(
      children: [
        Expanded(
          child: driverLocation.when(
            data: (loc) => _buildMap(loc),
            loading: () => _buildMap(null),
            error: (_, __) => _buildMap(null),
          ),
        ),
        _StatusBar(driverLocation: driverLocation),
      ],
    ),
  );
}
```

**Map markers:**
- Driver pin: `BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)` — updates as stream fires
- Shelter pin: `BitmapDescriptor.defaultMarker` (red) — static at `_shelterLatLng`
- Camera: `CameraUpdate.newLatLngBounds(bounds, padding: 80)` — fits both pins when both available; centers on shelter when driver not yet received

**`driverLocationProvider`** — a new `StreamProvider.family` wrapping `firestoreService.watchDriverLocation(driverId)`:

```dart
@riverpod
Stream<DriverLocationModel?> driverLocation(Ref ref, String driverId) =>
    ref.watch(firestoreServiceProvider).watchDriverLocation(driverId);
```

Add to `apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_provider.dart`.

---

## 6. Navigation Wiring

### 6.1 Router — add `/beneficiary/tracking` route

In `apps/mobile/lib/app/router.dart`, inside the `/beneficiary` route:

```dart
GoRoute(
  path: 'tracking',
  builder: (context, state) {
    final extra = state.extra! as Map<String, String>;
    return TrackingScreen(
      driverId: extra['driverId']!,
      beneficiaryId: extra['beneficiaryId']!,
    );
  },
),
```

### 6.2 "Track Delivery" button on `active_delivery_card.dart`

Add a "Track Delivery" `TextButton` to `ActiveDeliveryCard` that is shown when the delivery has a `driverId` set. On tap:

```dart
context.push('/beneficiary/tracking', extra: {
  'driverId': delivery.driverId!,
  'beneficiaryId': beneficiaryId, // passed into the card
});
```

---

## 7. Seed Data

The demo beneficiary documents in `tools/seed/` need `lat` and `lng` fields added.

Demo beneficiary — Sister Maria, Klong Toey Community Shelter, Bangkok:
- `lat: 13.7246`
- `lng: 100.5235`

Update the seed script to write these fields when creating/updating beneficiary documents.

---

## 8. Error Handling

| Scenario | Behaviour |
|---|---|
| Permission denied (first ask) | `AppLogger.warning`, tracking disabled silently. Batch job still proceeds without location. |
| Permission denied permanently | Same as above — no crash, no retry loop. |
| Location write fails (GPS error) | `AppLogger.warning`, next 30s tick retries automatically. |
| Location delete fails on stop | `catchError` → `AppLogger.warning`, non-blocking. |
| Beneficiary has no lat/lng | Shelter pin omitted; driver pin only shown. Map centers on driver. |
| Driver location doc not yet written | "Waiting for driver location…" status text; map shows shelter pin only. |

---

## 9. Tests

| File | What it covers |
|---|---|
| `test/unit/driver/driver_notifier_location_test.dart` | Permission denied → timer not started; `_stopTracking` calls `deleteLocation`; `_stopTracking` without prior `_startTracking` is a no-op |
| `test/widget/features/beneficiary/tracking_screen_test.dart` | Renders "Waiting for driver location" when stream is loading; renders status bar text when driver location arrives; shelter pin present when `_shelterLatLng` is set |

---

## 10. Files Changed Summary

| File | Change |
|---|---|
| `core/models/beneficiary_model.dart` | Add `double? lat`, `double? lng` |
| `services/firestore_service.dart` | Add `deleteDriverLocation(driverId)`, `getBeneficiary(beneficiaryId)` |
| `features/driver/data/datasources/driver_remote_datasource.dart` | Add `deleteLocation` |
| `features/driver/domain/repositories/driver_repository.dart` | Add `deleteLocation` |
| `features/driver/data/repositories/driver_repository_impl.dart` | Implement `deleteLocation` |
| `features/driver/presentation/providers/driver_notifier.dart` | Add `_activeDriverId`, async permission request, location doc delete on stop |
| `features/beneficiary/presentation/providers/beneficiary_provider.dart` | Add `driverLocationProvider` |
| `features/beneficiary/presentation/screens/tracking_screen.dart` | Replace TODO stub with full map |
| `features/beneficiary/presentation/widgets/active_delivery_card.dart` | Add "Track Delivery" button |
| `app/router.dart` | Add `/beneficiary/tracking` route |
| `tools/seed/` | Add `lat`/`lng` to beneficiary seed docs |
