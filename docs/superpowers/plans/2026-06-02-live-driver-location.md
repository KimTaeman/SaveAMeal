# Live Driver Location Broadcasting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire live driver location broadcasting end-to-end — permission request before tracking starts, location doc cleanup on job end, and a working `TrackingScreen` that shows the driver's moving pin and the shelter's fixed pin on a Google Map.

**Architecture:** `DriverNotifier` already has `_startTracking`/`_stopTracking` scaffolded with a 30-second timer; this plan adds permission gating and location doc deletion to those methods, then implements `TrackingScreen` as a `ConsumerStatefulWidget` that fetches the beneficiary's coordinates once and streams `driverLocations/{driverId}` in real time.

**Tech Stack:** Flutter (`geolocator ^13`, `google_maps_flutter ^2.9`, `flutter_riverpod ^3`), Firestore real-time snapshots.

---

## File Map

**Modified Flutter files:**
- `apps/mobile/lib/core/models/beneficiary_model.dart` — add `double? lat`, `double? lng`
- `apps/mobile/lib/services/firestore_service.dart` — add `deleteDriverLocation`, `getBeneficiary`
- `apps/mobile/lib/features/driver/data/datasources/driver_remote_datasource.dart` — add `deleteLocation`
- `apps/mobile/lib/features/driver/domain/repositories/driver_repository.dart` — add `deleteLocation`
- `apps/mobile/lib/features/driver/data/repositories/driver_repository_impl.dart` — implement `deleteLocation`
- `apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart` — permission + cleanup
- `apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_provider.dart` — add `driverLocationProvider`
- `apps/mobile/lib/features/beneficiary/presentation/screens/tracking_screen.dart` — replace TODO stub
- `apps/mobile/lib/features/beneficiary/presentation/widgets/active_delivery_card.dart` — add `onTrack` callback
- `apps/mobile/lib/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart` — wire `onTrack`
- `apps/mobile/lib/app/router.dart` — add `/beneficiary/tracking` route
- `tools/seed/seed.js` — add `lat`/`lng` to beneficiary docs

**Existing test file to update:**
- `apps/mobile/test/unit/driver/driver_notifier_test.dart` — add `deleteLocation` stub to `_FakeRepo`; add new tests

**New test file:**
- `apps/mobile/test/unit/driver/driver_notifier_location_test.dart` — permission denied + deleteLocation called

---

## Task 1: Add `lat`/`lng` to `BeneficiaryModel`

**Files:**
- Modify: `apps/mobile/lib/core/models/beneficiary_model.dart`

- [ ] **Step 1: Add the two fields**

Replace `apps/mobile/lib/core/models/beneficiary_model.dart` entirely:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'beneficiary_model.freezed.dart';
part 'beneficiary_model.g.dart';

@freezed
sealed class BeneficiaryModel with _$BeneficiaryModel {
  const factory BeneficiaryModel({
    required String id,
    required String name,
    String? address,
    double? lat,
    double? lng,
  }) = _BeneficiaryModel;

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) =>
      _$BeneficiaryModelFromJson(json);
}
```

- [ ] **Step 2: Regenerate Freezed code**

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```

Expected: ends with `[INFO] Running build completed` — no errors.

- [ ] **Step 3: Run tests to verify nothing broke**

```bash
cd apps/mobile && flutter test
```

Expected: all previously passing tests still pass.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/core/models/beneficiary_model.dart
git commit -m "feat: add lat/lng to BeneficiaryModel for shelter map pin"
```

---

## Task 2: Add `deleteDriverLocation` and `getBeneficiary` to `FirestoreService`

**Files:**
- Modify: `apps/mobile/lib/services/firestore_service.dart`

- [ ] **Step 1: Add both methods before the closing `}` of the class**

Open `apps/mobile/lib/services/firestore_service.dart`. Append before the final `}`:

```dart
  Future<void> deleteDriverLocation(String driverId) =>
      _db.collection(FirestoreConstants.driverLocations).doc(driverId).delete();

  Future<BeneficiaryModel?> getBeneficiary(String beneficiaryId) async {
    final doc = await _db
        .collection(FirestoreConstants.beneficiaries)
        .doc(beneficiaryId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return BeneficiaryModel.fromJson({...doc.data()!, 'id': doc.id});
  }
```

- [ ] **Step 2: Analyze**

```bash
cd apps/mobile && flutter analyze lib/services/firestore_service.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/lib/services/firestore_service.dart
git commit -m "feat: add deleteDriverLocation and getBeneficiary to FirestoreService"
```

---

## Task 3: Thread `deleteLocation` through the driver layer

**Files:**
- Modify: `apps/mobile/lib/features/driver/data/datasources/driver_remote_datasource.dart`
- Modify: `apps/mobile/lib/features/driver/domain/repositories/driver_repository.dart`
- Modify: `apps/mobile/lib/features/driver/data/repositories/driver_repository_impl.dart`
- Modify: `apps/mobile/test/unit/driver/driver_notifier_test.dart` (update `_FakeRepo`)

- [ ] **Step 1: Add `deleteLocation` to `DriverRemoteDatasource`**

Open `apps/mobile/lib/features/driver/data/datasources/driver_remote_datasource.dart`.

In the **abstract class**, add after `upsertLocation`:
```dart
  Future<void> deleteLocation(String driverId);
```

In **`DriverRemoteDatasourceImpl`**, add after the `upsertLocation` override:
```dart
  @override
  Future<void> deleteLocation(String driverId) =>
      _firestore.deleteDriverLocation(driverId);
```

- [ ] **Step 2: Add `deleteLocation` to `DriverRepository`**

Open `apps/mobile/lib/features/driver/domain/repositories/driver_repository.dart`.

Add after `upsertLocation`:
```dart
  Future<void> deleteLocation(String driverId);
```

- [ ] **Step 3: Implement in `DriverRepositoryImpl`**

Open `apps/mobile/lib/features/driver/data/repositories/driver_repository_impl.dart`.

Add after the `upsertLocation` override:
```dart
  @override
  Future<void> deleteLocation(String driverId) =>
      _datasource.deleteLocation(driverId);
```

- [ ] **Step 4: Update `_FakeRepo` in the existing test**

Open `apps/mobile/test/unit/driver/driver_notifier_test.dart`.

In `_FakeRepo`, add after `upsertLocation`:
```dart
  String? lastDeletedLocationDriverId;

  @override
  Future<void> deleteLocation(String driverId) async {
    lastDeletedLocationDriverId = driverId;
  }
```

- [ ] **Step 5: Run tests**

```bash
cd apps/mobile && flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/driver/data/datasources/driver_remote_datasource.dart \
        apps/mobile/lib/features/driver/domain/repositories/driver_repository.dart \
        apps/mobile/lib/features/driver/data/repositories/driver_repository_impl.dart \
        apps/mobile/test/unit/driver/driver_notifier_test.dart
git commit -m "feat: add deleteLocation to driver datasource, repository, and repo impl"
```

---

## Task 4: Update `DriverNotifier` — permission request and location cleanup

**Files:**
- Modify: `apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart`
- Create: `apps/mobile/test/unit/driver/driver_notifier_location_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `apps/mobile/test/unit/driver/driver_notifier_location_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';

class _FakeRepo implements DriverRepository {
  String? lastDeletedLocationDriverId;

  @override
  Future<void> claimBatch(String batchId, String driverId) async {}

  @override
  Future<void> confirmPickup(String batchId, String photoUrl) async {}

  @override
  Future<void> confirmDelivery(String batchId, String? notes) async {}

  @override
  Stream<List<BatchSummary>> getOpenBatches() => const Stream.empty();

  @override
  Stream<BatchSummary?> getActiveBatch(String driverId) => const Stream.empty();

  @override
  Future<void> upsertLocation(String driverId, double lat, double lng) async {}

  @override
  Future<void> deleteLocation(String driverId) async {
    lastDeletedLocationDriverId = driverId;
  }

  @override
  Stream<int> watchPoints(String uid) => const Stream.empty();
}

class _FakeDatasource implements DriverRemoteDatasource {
  @override
  Future<String> uploadPickupPhoto(String batchId, XFile photo) async =>
      'https://fake.url/photo.jpg';

  @override
  Stream<List<BatchModel>> watchOpenBatches() => const Stream.empty();

  @override
  Stream<BatchModel?> watchActiveBatch(String driverId) => const Stream.empty();

  @override
  Future<void> claimBatch(String batchId, String driverId) async {}

  @override
  Future<void> confirmPickup(String batchId, String pickupPhotoUrl) async {}

  @override
  Future<void> confirmDelivery(String batchId, String? notes) async {}

  @override
  Future<void> upsertLocation(String driverId, double lat, double lng) async {}

  @override
  Future<void> deleteLocation(String driverId) async {}

  @override
  Stream<int> watchPoints(String uid) => const Stream.empty();
}

ProviderContainer _makeContainer(_FakeRepo repo) => ProviderContainer(
  overrides: [
    driverRepositoryProvider.overrideWithValue(repo),
    driverRemoteDatasourceProvider.overrideWithValue(_FakeDatasource()),
  ],
);

void main() {
  test(
    'confirmDelivery calls deleteLocation with the driverId from claimBatch',
    () async {
      final repo = _FakeRepo();
      final container = _makeContainer(repo);
      final notifier = container.read(driverProvider.notifier);

      await notifier.claimBatch('b1', 'd1');
      expect(container.read(driverProvider).step, DriverStep.claimed);

      await notifier.confirmDelivery('b1', null);
      // Let the unawaited deleteLocation future complete.
      await Future<void>.delayed(Duration.zero);

      expect(repo.lastDeletedLocationDriverId, 'd1');
    },
  );

  test(
    'stopTracking without a prior startTracking is a no-op (no deleteLocation called)',
    () async {
      final repo = _FakeRepo();
      final container = _makeContainer(repo);
      final notifier = container.read(driverProvider.notifier);

      // Confirm delivery without ever claiming — _activeDriverId is null
      await notifier.confirmDelivery('b1', null);
      await Future<void>.delayed(Duration.zero);

      expect(repo.lastDeletedLocationDriverId, isNull);
    },
  );
}
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
cd apps/mobile
flutter test test/unit/driver/driver_notifier_location_test.dart
```

Expected: FAIL — compile error because `DriverRepository` doesn't have `deleteLocation` yet... wait, Task 3 already adds it. The failure here is that `DriverNotifier._stopTracking` doesn't call `deleteLocation` yet, and `_activeDriverId` doesn't exist. The test for `deleteLocation` will fail because `lastDeletedLocationDriverId` stays null.

- [ ] **Step 3: Replace `DriverNotifier`**

Replace `apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart` entirely:

```dart
import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/core/logging/app_logger.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';

part 'driver_notifier.g.dart';

@riverpod
class DriverNotifier extends _$DriverNotifier {
  Timer? _locationTimer;
  String? _activeDriverId;

  @override
  DriverState build() {
    ref.onDispose(_stopTracking);
    return const DriverState();
  }

  void selectBatch(BatchSummary batch) {
    state = state.copyWith(selectedBatch: batch);
  }

  void clearSelection() {
    state = state.copyWith(selectedBatch: null);
  }

  Future<void> claimBatch(String batchId, String driverId) async {
    await ref.read(driverRepositoryProvider).claimBatch(batchId, driverId);
    final batch = state.selectedBatch;
    state = state.copyWith(
      step: DriverStep.claimed,
      rescuePhase: ClaimRescuePhase.enRoutePickup,
      selectedBatch: null,
      activeBatch: batch,
    );
    // unawaited — permission dialog must not block the state transition
    unawaited(_startTracking(driverId));
    if (batch != null) {
      AppLogger.info(
        '[Job Accepted]\n'
        '  Driver UID (for seed)      : $driverId\n'
        '  Batch ID (manual QR code) : ${batch.id}\n'
        '  Donor                     : ${batch.donorName}\n'
        '  Pickup                    : ${batch.pickupAddress}\n'
        '  Window                    : ${batch.pickupWindowStart ?? '—'} – ${batch.pickupWindowEnd ?? '—'}\n'
        '  Beneficiary               : ${batch.beneficiaryName}\n'
        '  Drop-off                  : ${batch.beneficiaryAddress}\n'
        '  Portions                  : ${batch.totalPortions}\n'
        '  Instructions              : ${batch.specialInstructions ?? 'none'}',
      );
    }
  }

  Future<void> confirmPickup(String batchId, XFile photoFile) async {
    String photoUrl;
    try {
      photoUrl = await ref
          .read(driverRemoteDatasourceProvider)
          .uploadPickupPhoto(batchId, photoFile);
    } catch (e) {
      AppLogger.warning('Photo upload skipped', error: e);
      photoUrl = photoFile.path;
    }
    await ref.read(driverRepositoryProvider).confirmPickup(batchId, photoUrl);
    state = state.copyWith(
      step: DriverStep.pickedUp,
      rescuePhase: ClaimRescuePhase.enRouteBeneficiary,
    );
  }

  Future<void> confirmDelivery(String batchId, String? notes) async {
    await ref.read(driverRepositoryProvider).confirmDelivery(batchId, notes);
    _stopTracking();
    state = state.copyWith(step: DriverStep.delivered);
  }

  void resetToIdle() {
    state = const DriverState();
  }

  Future<void> _startTracking(String driverId) async {
    _activeDriverId = driverId;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permission denied — tracking disabled');
        return;
      }
    } catch (e) {
      // Platform not available (e.g. in unit tests) — skip tracking gracefully.
      AppLogger.warning('Location permission check unavailable', error: e);
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

  void _stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    if (_activeDriverId != null) {
      ref
          .read(driverRepositoryProvider)
          .deleteLocation(_activeDriverId!)
          .catchError(
            (Object e) =>
                AppLogger.warning('Location cleanup failed', error: e),
          );
      _activeDriverId = null;
    }
  }
}
```

- [ ] **Step 4: Run failing tests — expect PASS**

```bash
cd apps/mobile
flutter test test/unit/driver/driver_notifier_location_test.dart
```

Expected: `All 2 tests passed.`

- [ ] **Step 5: Run full test suite**

```bash
cd apps/mobile && flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart \
        apps/mobile/test/unit/driver/driver_notifier_location_test.dart
git commit -m "feat: add location permission request and cleanup to DriverNotifier"
```

---

## Task 5: Add `driverLocationProvider` to beneficiary providers

**Files:**
- Modify: `apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_provider.dart`

- [ ] **Step 1: Add the provider**

Open `apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_provider.dart`.

Add this import near the top (after existing imports). Note: `service_providers.dart` is already imported on line 10 — only add the `DriverLocationModel` line:
```dart
import 'package:saveameal/core/models/driver_location_model.dart';
```

Add this provider at the bottom of the file:
```dart
/// Live driver position — used by TrackingScreen to move the driver pin.
@riverpod
Stream<DriverLocationModel?> driverLocation(Ref ref, String driverId) =>
    ref.watch(firestoreServiceProvider).watchDriverLocation(driverId);
```

- [ ] **Step 2: Regenerate Riverpod code**

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```

Expected: `beneficiary_provider.g.dart` updated with `driverLocationProvider`. No errors.

- [ ] **Step 3: Analyze**

```bash
cd apps/mobile && flutter analyze lib/features/beneficiary/presentation/providers/beneficiary_provider.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_provider.dart \
        apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_provider.g.dart
git commit -m "feat: add driverLocationProvider for real-time driver position streaming"
```

---

## Task 6: Implement `TrackingScreen`

**Files:**
- Modify: `apps/mobile/lib/features/beneficiary/presentation/screens/tracking_screen.dart`

- [ ] **Step 1: Replace the TODO stub entirely**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saveameal/core/models/driver_location_model.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/services/service_providers.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({
    super.key,
    required this.driverId,
    required this.beneficiaryId,
  });

  final String driverId;
  final String beneficiaryId;

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  static const _driverMarkerId = MarkerId('driver');
  static const _shelterMarkerId = MarkerId('shelter');

  // Bangkok city centre — fallback before shelter coordinates load.
  static const _defaultTarget = LatLng(13.7563, 100.5018);

  LatLng? _shelterLatLng;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadShelterCoordinates();
  }

  Future<void> _loadShelterCoordinates() async {
    final ben = await ref
        .read(firestoreServiceProvider)
        .getBeneficiary(widget.beneficiaryId);
    if (!mounted) return;
    if (ben?.lat != null && ben?.lng != null) {
      setState(() => _shelterLatLng = LatLng(ben!.lat!, ben.lng!));
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(DriverLocationModel? driverLoc) {
    final markers = <Marker>{};
    if (driverLoc != null) {
      markers.add(
        Marker(
          markerId: _driverMarkerId,
          position: LatLng(driverLoc.lat, driverLoc.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Driver'),
        ),
      );
    }
    if (_shelterLatLng != null) {
      markers.add(
        Marker(
          markerId: _shelterMarkerId,
          position: _shelterLatLng!,
          infoWindow: const InfoWindow(title: 'Your Shelter'),
        ),
      );
    }
    return markers;
  }

  LatLng _cameraTarget(DriverLocationModel? driverLoc) {
    if (_shelterLatLng != null) return _shelterLatLng!;
    if (driverLoc != null) return LatLng(driverLoc.lat, driverLoc.lng);
    return _defaultTarget;
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(
      driverLocationProvider(widget.driverId),
    );
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final driverLoc = locationAsync.asData?.value;

    final statusText = locationAsync.when(
      data: (loc) =>
          loc != null ? 'Driver is on the way' : 'Waiting for driver location…',
      loading: () => 'Loading…',
      error: (_, __) => 'Unable to load driver location',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Delivery')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _cameraTarget(driverLoc),
                zoom: 14,
              ),
              markers: _buildMarkers(driverLoc),
              onMapCreated: (controller) => _mapController = controller,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacing.md),
            color: cs.surfaceContainerLow,
            child: Text(
              statusText,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
cd apps/mobile && flutter analyze lib/features/beneficiary/presentation/screens/tracking_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/lib/features/beneficiary/presentation/screens/tracking_screen.dart
git commit -m "feat: implement TrackingScreen with live driver pin and shelter pin"
```

---

## Task 7: Wire navigation — router + card + dashboard

**Files:**
- Modify: `apps/mobile/lib/app/router.dart`
- Modify: `apps/mobile/lib/features/beneficiary/presentation/widgets/active_delivery_card.dart`
- Modify: `apps/mobile/lib/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart`

- [ ] **Step 1: Add `/beneficiary/tracking` route to the router**

Open `apps/mobile/lib/app/router.dart`.

Add this import near the top with other beneficiary screen imports:
```dart
import 'package:saveameal/features/beneficiary/presentation/screens/tracking_screen.dart';
```

Inside the `/beneficiary` `GoRoute`'s `routes:` list, after the existing `delivery/:batchId` route, add:

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

- [ ] **Step 2: Add `onTrack` callback to `ActiveDeliveryCard`**

Replace `apps/mobile/lib/features/beneficiary/presentation/widgets/active_delivery_card.dart` entirely:

```dart
import 'package:flutter/material.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class ActiveDeliveryCard extends StatelessWidget {
  const ActiveDeliveryCard({
    super.key,
    required this.request,
    required this.onViewDetails,
    this.onTrack,
  });

  final IntakeRequest request;
  final VoidCallback onViewDetails;
  final VoidCallback? onTrack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final isDispatched = request.status == IntakeStatus.dispatched;

    final badgeColor = isDispatched ? ac.warning : cs.surfaceContainerHigh;
    final badgeTextColor = isDispatched ? ac.onWarning : cs.onSurfaceVariant;
    final badgeLabel = isDispatched ? 'IN TRANSIT' : 'AWAITING VOLUNTEER';

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cs.surfaceContainerLow,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    badgeLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: badgeTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (request.estimatedArrivalMinutes != null)
                  Text(
                    'ETA ${request.estimatedArrivalMinutes} min',
                    style: textTheme.labelMedium,
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              '${request.volunteerName ?? 'A volunteer'} is on the way',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${request.portions} portions • ${request.mealDescription}',
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                GestureDetector(
                  onTap: onViewDetails,
                  child: Text(
                    'View Details →',
                    style: textTheme.labelMedium?.copyWith(color: cs.primary),
                  ),
                ),
                if (onTrack != null && request.volunteerId != null) ...[
                  const SizedBox(width: Spacing.md),
                  GestureDetector(
                    onTap: onTrack,
                    child: Text(
                      'Track Delivery →',
                      style: textTheme.labelMedium?.copyWith(
                        color: cs.secondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Wire `onTrack` in `BeneficiaryDashboardScreen`**

Open `apps/mobile/lib/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart`.

Find lines 112–118 (the `ActiveDeliveryCard` instantiation inside `itemBuilder`) and replace with:

```dart
                  return ActiveDeliveryCard(
                    request: request,
                    onViewDetails: () => context.push(
                      '/beneficiary/delivery/${request.batchId}',
                    ),
                    onTrack: request.volunteerId != null
                        ? () => context.push(
                              '/beneficiary/tracking',
                              extra: <String, String>{
                                'driverId': request.volunteerId!,
                                'beneficiaryId': request.beneficiaryId,
                              },
                            )
                        : null,
                  );
```

- [ ] **Step 4: Run full test suite and analyze**

```bash
cd apps/mobile
flutter analyze
flutter test
```

Expected: no issues, all tests pass.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/app/router.dart \
        apps/mobile/lib/features/beneficiary/presentation/widgets/active_delivery_card.dart \
        apps/mobile/lib/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart
git commit -m "feat: wire TrackingScreen into router and add Track Delivery button to card"
```

---

## Task 8: Update seed data with beneficiary coordinates

**Files:**
- Modify: `tools/seed/seed.js`

- [ ] **Step 1: Add `lat`/`lng` to `BENEFICIARIES`**

Open `tools/seed/seed.js`. Replace the `BENEFICIARIES` array (lines 77–98) with:

```javascript
const BENEFICIARIES = [
  {
    id:      'ben_001',
    name:    'Baan Saeng Tawan Shelter',
    address: '12 Lat Phrao Soi 15, Chankasem, Chatuchak, Bangkok 10230',
    lat:     13.8102,
    lng:     100.5699,
  },
  {
    id:      'ben_002',
    name:    'Klongtoey Community Center',
    address: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    lat:     13.7246,
    lng:     100.5235,
  },
  {
    id:      'ben_003',
    name:    'Prateep Foundation Elderly Care',
    address: '152/88 Sukhumvit Soi 26, Khlong Toei, Bangkok 10110',
    lat:     13.7197,
    lng:     100.5663,
  },
  {
    id:      'ben_004',
    name:    'Bangkapi Community Kitchen',
    address: '45 Ladprao Rd, Wang Thonglang, Bangkok 10310',
    lat:     13.7814,
    lng:     100.5956,
  },
];
```

- [ ] **Step 2: Update the comment above the array**

Find the comment on line 76:
```javascript
// Collection: beneficiaries/{id}
// Fields: id (String), name (String), address (String?)
```

Replace with:
```javascript
// Collection: beneficiaries/{id}
// Fields: id (String), name (String), address (String?), lat (Number?), lng (Number?)
```

- [ ] **Step 3: Verify seed script runs**

```bash
cd /d/Desktop/KMUTT/SYSS/CSC234/new-flutter-app/tools/seed
node seed.js --emulator
```

Expected output includes:
```
✓  beneficiaries     4 documents
```

(Requires the Firebase emulator to be running: `firebase emulators:start --only firestore`)

- [ ] **Step 4: Commit**

```bash
cd /d/Desktop/KMUTT/SYSS/CSC234/new-flutter-app
git add tools/seed/seed.js
git commit -m "chore: add lat/lng coordinates to beneficiary seed documents"
```

---

## Final Verification

After all 8 tasks:

```bash
cd apps/mobile
flutter analyze
flutter test
```

Expected: no issues, all tests pass (the two new location tests join the existing suite).

**Manual demo check:**
1. Log in as a driver — accept a job → device should prompt for location permission.
2. Log in as a beneficiary — active delivery card with a claimed batch shows **"Track Delivery →"** link.
3. Tap "Track Delivery" → `TrackingScreen` opens with the shelter's red pin on the map.
4. As the driver moves (or wait 30s for the first write) → blue driver pin appears and moves.
5. Driver marks delivery complete → `driverLocations/{driverId}` doc is deleted in Firestore.

**Re-seed after adding coordinates:**
```bash
cd tools/seed && node seed.js --emulator --clean
```
