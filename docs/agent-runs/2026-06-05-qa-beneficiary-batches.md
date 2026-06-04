---
date: 2026-06-05
agent: qa-engineer
branch: feat/beneficiary-batches
pr-commits: c3763a3, 423ffec, 2090685
verdict: CHANGES REQUESTED
---

# QA Review — feat/beneficiary-batches

## Executive Summary

Unit coverage for new pure functions (`etaMinutes`, mapper pass-through) is solid. However, the most critical behaviour — the ETA throttle and the pickup-destination switch — are untested. `DriverInfoCard`'s three rendering states have no dedicated widget test. Two correctness bugs (silent stale-ETA on `confirmPickup`, timer-orphan on dispose) need code fixes, not just test gaps.

---

## Findings

### Finding 1 — Missing widget test for `DriverInfoCard` (three states)

**Severity:** HIGH — must be added

**File:** `apps/mobile/lib/features/beneficiary/presentation/widgets/driver_info_card.dart`

Three distinct render paths exist: (a) no driver — placeholder icon, (b) driver assigned / no GPS — GoogleMap at Bangkok fallback + "Locating driver…" chip, (c) driver assigned / live location — GoogleMap at real LatLng + "En route" chip. The existing `delivery_detail_screen_test.dart` exercises only state (b) incidentally. States (a) and (c) are never widget-tested.

**Required:** Create `test/widget/features/beneficiary/widgets/driver_info_card_test.dart` with `testWidgets` for all three states, overriding `driverLocationProvider` to avoid Firestore calls.

---

### Finding 2 — `_writeEtaIfChanged` throttle not unit-tested

**Severity:** HIGH — must be added

**File:** `apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart` (lines 199–216)

The central invariant — `repo.updateBatchEta` is only called when the integer-minute ETA changes — is never asserted. The three fake repos stub `updateBatchEta` but no test tracks call count. Tests pass with the stub silently swallowing all calls, which means they pass equally in the correct and broken states.

**Required:** Add tests verifying (a) no second write when ETA is unchanged, (b) second write fires when ETA changes. Extend `_FakeRepo.updateBatchEta` to track call count and last-argument.

---

### Finding 3 — Silent stale-ETA on `confirmPickup` when `beneficiaryLat/Lng` is null

**Severity:** MEDIUM — code fix + test required

**File:** `apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart` (lines 86–103)

If `activeBatchForDriverProvider` has not emitted the updated batch by the time `confirmPickup` is called (stream stale, network blip, or beneficiary doc has no `lat/lng`), `_destLat`/`_destLng` silently continue pointing at the pickup address. The ETA timer then writes ETAs to the donor location, not the beneficiary, with no error or log. Every existing `confirmPickup` test exercises this broken state (`asData?.value` returns null) and passes.

**Required:**
1. Add `AppLogger.warning('confirmPickup: beneficiary coordinates unavailable — ETA destination not updated')` when the guard condition is false.
2. Add a test asserting that warning fires when `beneficiaryLat` is null.
3. Add a test asserting destination switch happens correctly when coords are present (override `activeBatchForDriverProvider`).

Note: the architect review (Finding 2) recommends eliminating the `ref.read` stream re-query entirely by caching beneficiary coords at claim time — that fix also resolves this finding.

---

### Finding 4 — Timer-orphan if `dispose` fires during `getCurrentPosition` await

**Severity:** MEDIUM — code fix required

**File:** `apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart` (lines 140–179)

`_activeDriverId = driverId` is set at line 142, then `getCurrentPosition` is awaited. If `_stopTracking` fires (via `dispose`) during that await, it clears `_activeDriverId` and `_locationTimer`. When the await resumes, line 163 creates a new `Timer.periodic` and assigns it to `_locationTimer`, but `_stopTracking` has already run — the timer is never cancelled.

**Required fix:**
```dart
// After the initial-fix catch block (line ~162):
if (_activeDriverId == null) return; // disposed while awaiting initial fix
_locationTimer = Timer.periodic(...);
```

**Required test:** "dispose during initial GPS fix prevents timer creation."

---

### Finding 5 — `liteModeEnabled: true` is Android-only

**Severity:** LOW — comment only

**File:** `apps/mobile/lib/features/beneficiary/presentation/widgets/driver_info_card.dart` (line 91 approx)

`liteModeEnabled` is silently ignored on iOS — the full interactive map renders. Gesture locks still apply so the map isn't scrollable, but the intent (non-interactive minimap) is partially unmet.

**Recommendation:** Add a comment: `// Android only — full map renders on iOS but gesture locks still apply`.

---

### Finding 6 — `MapsConstants.mapId` is a hardcoded placeholder

**Severity:** LOW — pre-existing, now actively used

**File:** `apps/mobile/lib/core/constants/maps_constants.dart`

`'YOUR_MAP_ID_HERE'` is committed. This PR now passes it to `GoogleMap(mapId: ...)`. On Web, AdvancedMarkerElement initialisation fails silently.

**Recommendation:** Replace with `const String.fromEnvironment('MAPS_MAP_ID', defaultValue: '')` and add to CI web build step.

---

## Coverage Gaps Summary

| Gap | Status |
|---|---|
| Widget test: `DriverInfoCard` (3 states) | Missing — must be added |
| Unit test: `_writeEtaIfChanged` no-change path | Missing — must be added |
| Unit test: `_writeEtaIfChanged` change-triggers-write path | Missing — must be added |
| Unit test: `confirmPickup` with null `beneficiaryLat/Lng` | Silently passing in broken state — fix + test |
| Unit test: `confirmPickup` with valid `beneficiaryLat/Lng` | Missing — must be added |
| Unit test: dispose-during-GPS-fix timer orphan | Missing — should be added |
| Golden tests: `DeliveryDetailScreen`, `DriverInfoCard` | Directory does not exist |

**Solid coverage:** `etaMinutes` (6 tests), `batchModelToDetailDomain` pass-through + null (2 new tests), `claimBatch`/`confirmDelivery` state machine (pre-existing).

---

## Accessibility Findings

- Map `Semantics` label: 3 states correctly implemented, `excludeSemantics: true` correctly applied.
- ETA `Semantics(label: 'ETA: X minutes', excludeSemantics: true)` — correct; screen reader reads one coherent announcement.
- "ETA unknown" plain `Text` — acceptable; VoiceOver/TalkBack reads it naturally.
- `CircleAvatar` wrapped in `ExcludeSemantics` — correct.
- No new interactive widgets requiring button semantics.

---

## Performance Findings

- No new unbounded `ListView`. `GoogleMap` with `liteModeEnabled: true` and all gesture locks disabled is appropriate for a minimap.
- `Timer.periodic(30s)` is cancelled in `_stopTracking` which is registered via `ref.onDispose`. Timer leak is prevented in the normal path (see Finding 4 for the dispose-during-await edge case).
- `updateBatchEta` is a targeted single-field `.update()` — correct, not a full document rewrite.

---

## Verdict: CHANGES REQUESTED

Block on Findings 1 + 2 (DriverInfoCard widget test, `_writeEtaIfChanged` throttle tests). Findings 3 + 4 are correctness bugs that must be fixed before merge. Findings 5 + 6 may be tracked as follow-up.
