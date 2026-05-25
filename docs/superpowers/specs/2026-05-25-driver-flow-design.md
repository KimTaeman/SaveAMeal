# Driver Flow Design

**Date:** 2026-05-25
**Author:** Kim Taeman (architect)
**Status:** APPROVED

## Summary

Implement the full driver experience for SaveAMeal: browse open batches on a map, claim one via a Firestore transaction, confirm pickup via QR scan, share live location every 30 s, and mark the batch delivered. This completes the core `open → claimed → picked_up → delivered` lifecycle and creates the first end-to-end path through the app.

## Scope

- Replace the `DriverMapScreen` stub with a fully functional map + bottom-sheet screen.
- Delete dead stubs: `PickupScreen`, `DeliveryScreen` (their logic is absorbed into `DriverMapScreen`).
- Wire up the existing `BatchQrScreen` stub as the QR confirmation step.
- Implement `DriverDatasource`, `DriverRepositoryImpl`, and all domain use cases for the driver role.
- Add live location writes to `driverLocations/{uid}` via `LocationService`.

## Screens & Navigation

### DriverMapScreen (replaces stub)

One screen with two visual states, driven by `DriverState.step`:

**Browse state** (`step == DriverStep.browsing`)
- `GoogleMap` fills the screen.
- Open batches rendered as custom `Marker`s from `openBatchesProvider`.
- Tapping a marker sets `DriverState.selectedBatch` and slides up a `DraggableScrollableSheet` showing: donor name, pickup address, item count, and a "Claim Batch" primary button.
- If claim fails (race condition), dismiss sheet and show a snackbar: "Batch already taken — try another."

**Active delivery state** (`step != DriverStep.browsing`)
- Map stays live; camera animates to the relevant destination.
- Bottom sheet is non-dismissible; content is a `Stepper` with three steps:
  1. **Claimed** — "Navigate to Donor" (opens Maps deep-link) + "Confirm Pickup" (pushes `BatchQrScreen`).
  2. **Picked Up** — "Navigate to Beneficiary" + "Mark Delivered" button.
  3. **Delivered** — Completion message; sheet collapses after 2 s and screen returns to browse state.

**Navigation:** `BatchQrScreen` is pushed via GoRouter. On successful QR scan it pops and the notifier transitions to `pickedUp`. No other new routes needed.

## Data Layer

### Firestore reads

| Provider | Query | Notes |
|---|---|---|
| `openBatchesProvider` | `batches` where `status == "open"` | StreamProvider; populates markers |
| `activeBatchProvider` | `batches` where `claimedBy == uid` and `status in [claimed, picked_up]` limit 1 | StreamProvider; drives active delivery state |

### Firestore writes (`DriverDatasource`)

| Method | Operation | Side effects |
|---|---|---|
| `claimBatch(batchId)` | Firestore transaction: assert `status == "open"`, write `status = "claimed"`, `claimedBy`, `claimedAt` | Throws `BatchAlreadyClaimedException` on conflict |
| `confirmPickup(batchId)` | Write `status = "picked_up"`, `pickedUpAt` | — |
| `confirmDelivery(batchId)` | Write `status = "delivered"`, `deliveredAt` | Triggers `onDeliveryComplete` Cloud Function |

### Location writes (`LocationService`)

- Uses `geolocator` package (already in architecture).
- `Timer.periodic(const Duration(seconds: 30))` writes `{lat, lng, updatedAt: FieldValue.serverTimestamp()}` to `driverLocations/{uid}`.
- Timer lifecycle: **start** on successful `claimBatch`; **cancel** on `confirmDelivery` or `AppLifecycleState.paused`.

## State

```dart
enum DriverStep { browsing, claimed, pickedUp, delivered }

// Lives in presentation/providers/ — not domain — because it references BatchModel.
@freezed
class DriverState with _$DriverState {
  const factory DriverState({
    BatchModel? activeBatch,
    BatchModel? selectedBatch,
    @Default(DriverStep.browsing) DriverStep step,
  }) = _DriverState;
}
```

`DriverNotifier extends AsyncNotifier<DriverState>` exposes:
- `selectBatch(BatchModel)` — sets `selectedBatch`, opens sheet.
- `claimBatch(String batchId)` — calls datasource, starts location timer, transitions to `claimed`.
- `confirmPickup(String batchId)` — calls datasource, transitions to `pickedUp`.
- `confirmDelivery(String batchId)` — calls datasource, cancels timer, transitions to `delivered`, then resets to `browsing` after 2 s.

Supporting providers (read-only, no state mutations):
- `openBatchesProvider` — `StreamProvider<List<BatchModel>>`.
- `activeBatchProvider` — `StreamProvider<BatchModel?>`.

## Domain Use Cases

| Use case | Input | Output |
|---|---|---|
| `GetOpenBatchesUseCase` | — | `Stream<List<Batch>>` |
| `GetActiveBatchUseCase` | `String uid` | `Stream<Batch?>` |
| `ClaimBatchUseCase` | `String batchId, String uid` | `Future<void>` |
| `ConfirmPickupUseCase` | `String batchId` | `Future<void>` |
| `ConfirmDeliveryUseCase` | `String batchId` | `Future<void>` |

## Error Handling

- `BatchAlreadyClaimedException` — caught in notifier, surfaced as snackbar ("Batch already taken").
- `LocationPermissionDeniedException` — surfaced as a dialog on first claim; driver cannot proceed without location permission.
- Firestore stream errors — `AsyncValue.error` shown as an error widget with a retry button.

## Testing

### Widget tests (`test/widget/driver/driver_map_screen_test.dart`)

1. Browse state: map widget present, bottom sheet initially collapsed.
2. Marker tap → sheet slides up with batch detail and Claim button.
3. Claimed state: stepper visible at step 0 ("Claimed"), Confirm Pickup button present.
4. PickedUp state: stepper at step 1, Mark Delivered button present.
5. Claim failure: snackbar with "Batch already taken" message appears.

All Riverpod providers overridden with fakes; `GoogleMap` replaced by a `Key`-findable stub widget.

### Unit tests (`test/unit/driver/`)

1. `ClaimBatchUseCase` — success path writes correct Firestore fields.
2. `ClaimBatchUseCase` — throws `BatchAlreadyClaimedException` when transaction reads `status != "open"`.
3. `DriverNotifier.claimBatch` — location timer is non-null after success.
4. `DriverNotifier.confirmDelivery` — location timer is null after delivery.

## Files Added / Modified

```
apps/mobile/lib/features/driver/
  presentation/providers/driver_state.dart    (new — DriverState + DriverStep enum)
  domain/usecases/get_open_batches_usecase.dart (new)
  domain/usecases/get_active_batch_usecase.dart (new)
  domain/usecases/claim_batch_usecase.dart    (new)
  domain/usecases/confirm_pickup_usecase.dart (new)
  domain/usecases/confirm_delivery_usecase.dart (new)
  domain/repositories/driver_repository.dart  (new)
  data/datasources/driver_datasource.dart     (new)
  data/repositories/driver_repository_impl.dart (new)
  presentation/providers/driver_notifier.dart (new, codegen)
  presentation/screens/driver_map_screen.dart (replace stub)
  presentation/screens/pickup_screen.dart     (delete)
  presentation/screens/delivery_screen.dart   (delete)

apps/mobile/lib/services/location_service.dart (new or extend)
apps/mobile/lib/features/donor/presentation/screens/batch_qr_screen.dart (implement QR display)

apps/mobile/test/widget/driver/driver_map_screen_test.dart (new)
apps/mobile/test/unit/driver/claim_batch_usecase_test.dart (new)
apps/mobile/test/unit/driver/driver_notifier_test.dart (new)
```

## Open Questions

- Does `BatchQrScreen` generate a QR or just display the `batchId` as text/QR for the driver to scan on their own device? Assumed: displays a `qr_flutter`-generated QR code containing the `batchId`.
- Does the driver see beneficiary address or only the donor pickup address? Assumed: both — donor address at Claimed step, beneficiary address at PickedUp step.
