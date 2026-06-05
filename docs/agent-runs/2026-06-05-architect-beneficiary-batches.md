# Architect Review — feat/beneficiary-batches

**Date:** 2026-06-05
**Branch:** feat/beneficiary-batches → main
**Reviewer:** architect agent
**ADR written:** docs/decisions/0018-eta-computation-placement.md

---

## Executive Summary

The PR delivers three coherent features: a map-gating UI fix in `DriverInfoCard`, a
`BatchModel` schema extension (`estimatedArrivalMinutes`, `beneficiaryLat`,
`beneficiaryLng`), and a live ETA streaming pipeline routed through the driver tracking
loop. The overall layer topology is sound: the Domain layer remains free of Flutter and
Firebase imports, the Data layer owns all Firestore I/O, and the Presentation layer calls
the domain only through the `DriverRepository` interface (with one documented exception
described below).

Two issues require changes before merge. One is architectural — ETA business logic
computed inside the Presentation layer without a use-case wrapper, inconsistent with every
other write-path in the driver feature. The second is a correctness risk — `confirmPickup`
reads a stream provider with `ref.read`, which can return stale beneficiary coords and
silently continue routing the ETA to the pickup address after pickup. Four lower-severity
observations are noted for awareness but do not block the merge on their own.

---

## Findings

### Finding 1 — ETA computation lives in `DriverNotifier` with no use-case wrapper

**Severity:** MEDIUM (architecture violation — blocks merge on its own only in conjunction
with Finding 2; the two together constitute a clear use-case-bypass on a write path)

**File:** `apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart`
lines 199–215 (`_writeEtaIfChanged`)

**Description:**
`_writeEtaIfChanged` calls `etaMinutes()` (a pure-Dart calculation) and then calls
`_repo.updateBatchEta(batchId, newEta)` — a write operation with integer-minute throttle
logic — entirely within `DriverNotifier`. This is the only write path in the driver feature
that has no use-case class in `domain/usecases/`. Every other write (`claimBatch`,
`confirmPickup`, `confirmDelivery`, `upsertLocation`) is either wrapped in a use-case or
trivially delegated through the repository. ADR-0013 explicitly permits bypassing use cases
only for "read-only streams with no business logic." Writing to Firestore with throttle
logic does not qualify.

Additionally, `distance_utils.dart` lives at `core/utils/` and carries zero framework
imports. Importing it from `driver_notifier.dart` is a valid `core` → `presentation`
reference and is not itself a violation. However, the fact that the *only consumer* of
`etaMinutes()` is a single notifier, and that the throttle condition and the write call are
inseparable, means the correct home for this logic is a domain use case.

**Recommendation:**
Create `apps/mobile/lib/features/driver/domain/usecases/update_batch_eta_usecase.dart`:

```dart
// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/core/utils/distance_utils.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class UpdateBatchEtaUsecase {
  const UpdateBatchEtaUsecase(this._repository);
  final DriverRepository _repository;

  Future<void> call({
    required String batchId,
    required double driverLat,
    required double driverLng,
    required double destLat,
    required double destLng,
    int? lastEtaMinutes,
  }) async {
    final newEta = etaMinutes(driverLat, driverLng, destLat, destLng);
    if (newEta == lastEtaMinutes) return;
    await _repository.updateBatchEta(batchId, newEta);
  }
}
```

`DriverNotifier._writeEtaIfChanged` then becomes:

```dart
final newEta = await _updateBatchEtaUsecase.call(
  batchId: batchId, driverLat: driverLat, driverLng: driverLng,
  destLat: destLat, destLng: destLng, lastEtaMinutes: _lastEtaMinutes,
);
// use case handles no-op internally; caller only needs to update _lastEtaMinutes
```

The use case can either return the computed value or a bool indicating whether a write
occurred so the notifier can update `_lastEtaMinutes`. The direct import of
`distance_utils.dart` is removed from `driver_notifier.dart`.

---

### Finding 2 — `confirmPickup` reads `activeBatchForDriverProvider` with `ref.read` — stale-value risk

**Severity:** MEDIUM (correctness — ETA destination silently stays at pickup coords on
the post-pickup leg if the Firestore write from `claimBatch` has not yet propagated)

**File:** `apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart`
lines 90–102

**Description:**
After `confirmPickup` writes `status: pickedUp` to Firestore, the code immediately reads
`activeBatchForDriverProvider(_activeDriverId!).asData?.value` to obtain `beneficiaryLat`
and `beneficiaryLng`. This is a `ref.read` on a stream provider, which returns whatever
value the Riverpod cache currently holds — it does not wait for the Firestore snapshot to
refresh. The beneficiary coords were written to the batch document during `claimBatch`
(the transaction in `FirestoreService.claimBatch`), so they *should* be present in the
cache from the time the batch was claimed. However, if the stream cache was invalidated
between claim and pickup (dispose/rebuild cycle, provider scope change, network blip), the
read returns `null` and the ETA destination is never switched, leaving the driver's ETA
pointing at the donor's pickup address for the entire delivery leg. The failure is silent:
no error is thrown and no state is set to reflect the problem.

There is a secondary concern: `_destLat` and `_destLng` are set to the pickup coords in
`claimBatch`, and if `confirmPickup` fails the coord swap, the timer continues writing ETAs
to the batch document against the pickup coords, not the beneficiary's address. Beneficiaries
would see a misleading countdown for the wrong location.

**Recommendation:**
At the time `claimBatch` succeeds, the `BatchSummary` selected by the driver already
carries `beneficiaryLat` and `beneficiaryLng` (they are mapped through `_toSummary` in
`DriverRepositoryImpl`). Cache these values in `DriverNotifier` private state at
`claimBatch` time instead of fetching them again from the stream provider at `confirmPickup`
time:

```dart
// In claimBatch():
_beneficiaryLat = batch?.beneficiaryLat;
_beneficiaryLng = batch?.beneficiaryLng;

// In confirmPickup():
if (_beneficiaryLat != null && _beneficiaryLng != null) {
  _destLat = _beneficiaryLat;
  _destLng = _beneficiaryLng;
  _lastEtaMinutes = null;
}
```

This eliminates the `ref.read` on the stream provider entirely, which is the right pattern
— notifiers should not re-query reactive providers to recover state they already held.
`_beneficiaryLat` and `_beneficiaryLng` must be cleared in `_stopTracking`.

---

### Finding 3 — `BatchItemModel` imported into the Domain layer

**Severity:** LOW (existing pre-PR issue; not introduced by this diff, but the PR extends
`BatchSummary` and is therefore an opportunity to flag it)

**File:** `apps/mobile/lib/features/driver/domain/repositories/driver_repository.dart`
line 2

**Description:**
`BatchSummary` is a domain entity that imports
`package:saveameal/core/models/batch_item_model.dart`. `BatchItemModel` is a Freezed model
(it imports `freezed_annotation`) and lives in `core/models/`, not in any domain layer.
`freezed_annotation` is a code-generation annotation package, not a Flutter or Firebase
package, so it does not fail the "zero Flutter or backend imports" rule in the strictest
reading. However, the domain layer now depends on a data-layer model class — the `@freezed`
annotation, the generated `.freezed.dart` part file, and the `json_serializable` plumbing
are all data-layer concerns. Domain entities should be plain Dart classes with no
code-generation annotations.

This PR adds `beneficiaryLat`/`beneficiaryLng` to `BatchSummary` (domain) as `double?`
fields — that addition is correct and clean. But the `items: List<BatchItemModel>` field on
`BatchSummary` remains a coupling that should eventually be resolved by introducing a domain
`BatchItem` value object.

**Recommendation:**
Do not block merge on this alone. Track it as a known debt item. In the next spec that
touches `BatchSummary`, introduce a domain `BatchItem` value object in
`features/driver/domain/entities/batch_item.dart` (pure Dart, no Freezed) and stop passing
`BatchItemModel` through the domain boundary. The `_toSummary` mapper in
`DriverRepositoryImpl` performs the translation at the data→domain boundary.

---

### Finding 4 — `beneficiaryLat`/`beneficiaryLng` denormalisation couples claim flow to beneficiary schema

**Severity:** LOW (design debt — not a layer violation, but a schema coupling)

**File:** `apps/mobile/lib/services/firestore_service.dart` lines 302–313 (`claimBatch`)

**Description:**
During the claim transaction, `FirestoreService.claimBatch` reads
`beneficiaries/{resolvedBeneficiaryId}` and copies `lat`/`lng` onto the batch document.
This is a conscious denormalisation decision and is architecturally acceptable — the batch
document becomes self-contained for driver ETA without a second Firestore read. The risk is
coupling: if the beneficiary document schema changes its lat/lng field names (e.g., to
`latitude`/`longitude` or a GeoPoint type), `claimBatch` silently writes `null` with no
error. Existing batches would show no ETA until re-claimed.

There is also a correctness edge case: if a beneficiary moves their registered address after
a batch is claimed, the driver navigates to the stale coordinates. This is acceptable for a
V1 feature but should be noted.

**Recommendation:**
Add a comment in `claimBatch` naming the schema dependency explicitly:
`// Assumes beneficiaries/{id} stores lat/lng as num fields named 'lat' and 'lng'.`
Consider adding a Firestore security rule test that validates these fields exist and are
numeric before the next release. No code change required to unblock this PR.

---

### Finding 5 — `UpdateBatchEta` belongs on `DriverRepository`; no need to move it

**Severity:** INFO (confirming existing placement is correct)

**File:** `apps/mobile/lib/features/driver/domain/repositories/driver_repository.dart`

**Description:**
The PR adds `updateBatchEta(String batchId, int eta)` to the `DriverRepository` interface.
The question of whether it belongs on a more generic `BatchRepository` was raised. It does
not. The ETA field is written exclusively by the driver tracking loop; no other actor
(beneficiary, donor, admin) writes this field. Placing it on `DriverRepository` correctly
reflects the ownership model. A separate `BatchRepository` for ETA would add an abstraction
with one implementor and one caller, gaining nothing.

---

### Finding 6 — `DriverInfoCard` UI fix: clean, no issues

**Severity:** INFO (no violation)

**File:** `apps/mobile/lib/features/beneficiary/presentation/widgets/driver_info_card.dart`

**Description:**
The 3-state map gating (`volunteerId == null` / `driverLoc == null` / `driverLoc != null`),
Bangkok fallback `defaultTarget`, `StackFit.expand` on the map container, and the status
chip are all pure Presentation-layer concerns. `AppColors` and `ColorScheme` are accessed
via `ac` and `cs` per convention. `Theme.of(context).textTheme` is used for all typography.
No hardcoded colors or magic numbers observed. The `Semantics`/`ExcludeSemantics` usage is
correct. No architecture concerns.

---

## Tradeoffs

- **ETA use-case wrapper (Finding 1):** Upside: write paths are uniformly testable at the
  domain boundary; throttle logic is unit-testable without a Riverpod harness. Downside:
  one additional file; the use case returns a computed value that the notifier still needs
  to cache as `_lastEtaMinutes`. Cost of reversal if team rejects: low — the logic moves
  back into the notifier with a three-line change.

- **Caching beneficiary coords in notifier vs re-reading stream (Finding 2):** Upside:
  eliminates the stale-read window entirely; `_destLat`/`_destLng` swap is synchronous and
  deterministic. Downside: if the beneficiary's coords change between claim and pickup,
  the cached value is outdated — but this is acceptable and the denormalisation in
  `claimBatch` has the same limitation. Cost of reversal: low.

- **Domain `BatchItem` entity vs continuing with `BatchItemModel` (Finding 3):** Upside:
  Domain layer becomes fully framework-free; data-layer schema changes can no longer leak
  into `BatchSummary`. Downside: mapper boilerplate in `_toSummary`; items list grows one
  more translation step. Cost of reversal if entity is added then removed: low.

---

## Verdict

**CHANGES REQUESTED**

Finding 1 (ETA logic in Presentation without a use-case wrapper on a write path) and
Finding 2 (stale `ref.read` on stream provider in `confirmPickup`) must both be addressed
before merge. Findings 3–6 are documented but do not block. The layer structure is
otherwise sound, the domain is free of Flutter and Firebase imports, and the schema
additions are correctly placed.
