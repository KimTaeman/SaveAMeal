# QA Review — feat/beneficiary-batches
Date: 2026-06-04
Reviewer: qa-engineer

---

## Test Results
- Tests: 247 (all pass)
- `flutter analyze`: 0 issues
- `dart format --set-exit-if-changed`: 0 changes

---

## Findings

### [BLOCKING] FIXED — No semantic labels on any interactive widget in new screens
`DriverInfoCard`, `BatchItemsCard`, `RecentDeliveriesSection`, and `DeliveryDetailScreen`
had zero `Semantics`, `semanticLabel`, or `Tooltip` wrappers.

**Fix applied (commit df41269):**
- `DriverInfoCard` map section: wrapped `ClipRRect` in
  `Semantics(label: 'Driver location map — ...', excludeSemantics: true)`.
- `DriverInfoCard` avatar: wrapped in `ExcludeSemantics` (name Text is the readable label).
- `DriverInfoCard` ETA column: wrapped in `Semantics(label: 'ETA: N minutes', excludeSemantics: true)`
  to merge the two-line display into one screen-reader string.
- `RecentDeliveriesSection` leading check-circle and trailing chevron: wrapped in `ExcludeSemantics`.
- `DeliveryDetailScreen` notifications `IconButton`: added `tooltip: 'Notifications'`.

---

### [BLOCKING] FIXED — "View All" touch target below 44 dp (WCAG 2.2 SC 2.5.8)
`TextButton.styleFrom(minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap)`
collapsed the tap target to ~14 dp.

**Fix applied (commit df41269):** Removed `minimumSize: Size.zero` and
`tapTargetSize: MaterialTapTargetSize.shrinkWrap`, restoring the Material 3
default 48 dp touch target.

---

### [WARNING] `BatchItemsCard` and `DriverInfoCard` have no dedicated widget tests
The screen tests exercise both widgets indirectly but do not cover: zero-item list,
long `donorName` overflow, `DriverInfoCard` with `volunteerId != null` but loading
driver location, `volunteerName == null` initials fallback, or
`estimatedArrivalMinutes == null` "ETA unknown" branch.

Recommended fix: add `batch_items_card_test.dart` and `driver_info_card_test.dart`.

### [WARNING] Silent error swallowing with no logging
`RecentDeliveriesSection` error callback and `DriverInfoCard` driver-location null
fallback both silently discard errors. No `AppLogger` call in either path.

Recommended fix: call `AppLogger.e(...)` before returning `SizedBox.shrink()`.

### [WARNING] `estimatedArrivalMinutes` and `cancellationReason` hardcoded null
`batchModelToDetailDomain` always maps these to `null`; ETA always shows "ETA unknown"
in production and the cancellation banner never shows a reason. A follow-up spec task
must add these fields to `BatchModel` and wire them through the mapper.

### [WARNING] `beneficiaryId ?? ''` empty-string fallback
If `batch.beneficiaryId` is missing from Firestore, `IntakeRequestDetail.beneficiaryId`
becomes `''`, which is passed to `recentDeliveriesProvider('')` and fires an
unintended Firestore query.

### [INFO] `pumpAndSettle()` called without explicit duration in 3 test sites
Recommended fix: use `await tester.pumpAndSettle(const Duration(seconds: 3))`.

### [INFO] No golden tests for `DeliveryDetailScreen`
QA convention requires one golden per screen at text scales 1.0 and 1.5.

### [INFO] CI does not run `integration_test/`
`.github/workflows/ci.yml` runs `flutter test --coverage` but omits
`flutter test integration_test/`.

---

## CLAUDE.md Rules Checklist
- [x] `flutter analyze` — 0 issues
- [x] `dart format` — no diff
- [x] New screens have widget tests
- [x] No unbounded `ListView` (`ListView.builder` with `shrinkWrap: true, NeverScrollableScrollPhysics()`)
- [x] No `Image.network` — no remote images used
- [x] Domain layer is pure Dart
- [x] Semantic labels present on interactive widgets (after df41269)
- [x] Touch target ≥ 44 dp on "View All" (after df41269)

---

## Verdict
**CHANGES REQUESTED** (at time of initial review)

Both blocking findings have since been resolved in commit `df41269`.
Four warnings remain as follow-up work; none are blocking for merge.

Blocking findings at initial review: missing semantic labels, undersized "View All" touch target —
both now resolved.
