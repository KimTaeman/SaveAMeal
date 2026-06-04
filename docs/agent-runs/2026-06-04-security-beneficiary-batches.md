# Security Review — feat/beneficiary-batches
Date: 2026-06-04
Reviewer: security-reviewer

---

## Findings

### [CRITICAL] FIXED — Google Maps API key hardcoded in AndroidManifest.xml (CWE-321/798)
`apps/mobile/android/app/src/main/AndroidManifest.xml` previously contained
`AIzaSyDk0nptxIoDGIYOYhYplzEW3t8simNv9Rw` as a plaintext literal. This key is
now live because `DriverInfoCard` (introduced in this PR) is the first feature
to invoke `google_maps_flutter`.

**Fix applied (commit 5dc082c):** Replaced literal with `${MAPS_API_KEY}` manifest
placeholder. `build.gradle.kts` reads the value from `local.properties` (dev) or
the `MAPS_API_KEY` environment variable (CI). `local.properties` is gitignored.

**Remaining action required by team:** Rotate the old key in GCP Console and apply
Android app restrictions (SHA-1 + package name) to the replacement key.

---

### [CRITICAL] FIXED — IDOR on DeliveryDetailScreen — any authenticated user could view any batch (CWE-639)
`intakeRequestDetailProvider` accepted a raw `batchId` from the URL path parameter
and called `watchBatch(batchId)` with no ownership check. The Firestore rule for
`batches` was `allow read: if isSignedIn()`, meaning any logged-in user of any role
could read full batch detail (items, volunteer name, donor name, live driver location)
for any batch by crafting the URL `/beneficiary/delivery/<batchId>`.

**Fix applied (commit 5dc082c):** `watchIntakeRequestDetail(batchId, beneficiaryId)`
now takes the caller's UID as a second parameter. `FirestoreIntakeRepository` rejects
batches whose `beneficiaryId` field does not equal the passed UID, emitting `null`
instead. The Riverpod provider reads `currentUser.uid` from `authStateProvider` and
threads it through — a crafted URL for a foreign batch now returns the
"Delivery not found" state.

**Remaining action (not in this PR scope):** Tighten the Firestore Security Rule for
`batches` from `allow read: if isSignedIn()` to role + ownership scoped reads.

---

### [HIGH] Firebase API keys in tracked config files (CWE-321)
`firebase_options.dart`, `google-services.json`, and `GoogleService-Info.plist`
are committed and contain live Firebase API keys. These are pre-existing issues
not introduced by this PR. Recommended: untrack the two platform config files
(`git rm --cached`) and distribute them via CI secrets.

### [HIGH] `watchRecentDeliveriesForBeneficiary` uses limit(20) + client-side take(3)
The query fetches up to 20 documents to return 3, wasting Firestore read quota and
re-reading all 20 documents on every snapshot. Recommended fix: add
`orderBy('deliveredAt', descending: true).limit(3)` directly in the Firestore query
(requires composite index).

### [HIGH] `cancellationReason` from Firestore rendered verbatim in cancellation banner
Flutter `Text` does not execute HTML/JS, so XSS is not applicable. However, a
compromised document could display misleading text. Recommend field-length
truncation in `batchModelToDetailDomain` as a precaution.

### [HIGH] `driverLocationProvider` accepts arbitrary driverId with no ownership constraint
Pre-existing `allow read: if isSignedIn()` rule on `driverLocations` means any
authenticated user can watch any driver's real-time GPS. This is partially mitigated
by the CRITICAL-2 fix (a crafted URL for a foreign batch now returns null), but the
Firestore rule itself should be tightened.

### [MEDIUM] `watchIntakeRequestDetail` reuses `watchBatch` (unfiltered single-document read)
The data-layer method does not encode the beneficiary constraint; the ownership check
exists only in the repository layer. A `watchBatchForBeneficiary(batchId, beneficiaryId)`
datasource method would make the constraint testable at the correct layer.

### [LOW] `portions` derived from `items.length` — semantically incorrect for weight-based batches
Not a security risk; a data-integrity concern for beneficiary trust in the UI.

### [INFO]
- `AppLogger` correctly gates `debugPrint` behind `kDebugMode`; no PII logged in new files.
- `_normalise()` correctly handles `Timestamp` → `DateTime` conversion.
- Domain entities are pure Dart with zero backend imports.
- `GoogleMap` rendered with `liteModeEnabled: true`, all gesture handlers disabled.
- Widget tests use provider overrides; no real Firestore or Maps platform calls.

---

## Verdict
**CHANGES REQUESTED** (at time of initial review)

Both CRITICAL findings have since been resolved in commit `5dc082c`.
HIGH findings (Firebase config files, query efficiency, Firestore rule tightening)
remain open as follow-up work.

Blocking findings at initial review: CRITICAL-1, CRITICAL-2 — both now resolved.
