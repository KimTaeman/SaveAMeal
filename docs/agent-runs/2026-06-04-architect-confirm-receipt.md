# Architect Review — feat/confirm-receipt

**Date:** 2026-06-04
**Branch:** feat/confirm-receipt → main
**Reviewer:** architect
**Spec:** SPEC-0008 (`tech-specs/0008-confirm-receipt.md`)
**ADR written:** `docs/decisions/0017-intake-status-enum-extension.md`

---

## Summary

The implementation is substantially correct and the domain layer is clean. Two issues block merge: a `copyWith` bug that silently clears error state on every star tap and text keystroke, and a domain entity (`IntakeRequestDetail`) being passed through the GoRouter `extra` field in a way that diverges from the spec. Three lower-severity findings follow.

---

## Issues

### BLOCKER-1 — `copyWith` always overwrites `error` with `null` when the field is not passed

**Location:** `apps/mobile/lib/features/beneficiary/presentation/providers/confirm_receipt_provider.dart`, lines 22–34

The `copyWith` implementation uses `error: error` without a null-coalescing fallback:

```dart
ConfirmReceiptState copyWith({
  ...
  String? error,
  ...
}) => ConfirmReceiptState(
  ...
  error: error,           // <-- always writes null when caller omits the field
  ...
);
```

Because `String? error` defaults to `null` when the caller does not pass it, any call to `copyWith` that does not explicitly pass `error:` silently discards an existing error string. Concretely:

- `setRating(value)` calls `state.copyWith(rating: value)` — if an error message is currently displayed (e.g., a prior network failure), tapping any star wipes the error from the UI without the user having acknowledged it.
- `setFeedback(value)` calls `state.copyWith(feedback: value)` — every keystroke in the text field wipes the error.

The submit path at line 57 (`state.copyWith(isSubmitting: true, error: null)`) intentionally clears the error and is correct. All other call sites are not.

**Fix:** Use the standard nullable-clear pattern — introduce a sentinel or use a separate `clearError` flag, or follow the Freezed convention of a wrapper type. The minimal fix is:

```dart
ConfirmReceiptState copyWith({
  int? rating,
  String? feedback,
  bool? isSubmitting,
  Object? error = _sentinel,   // sentinel distinguishes "not provided" from explicit null
  bool? submitted,
}) {
  return ConfirmReceiptState(
    rating: rating ?? this.rating,
    feedback: feedback ?? this.feedback,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: identical(error, _sentinel) ? this.error : error as String?,
    submitted: submitted ?? this.submitted,
  );
}

static const Object _sentinel = Object();
```

**Why it matters:** The error snackbar and the disabled-button state both depend on `error != null`. Silently clearing the error on a star tap makes the error recovery path untestable and confusing to users.

---

### BLOCKER-2 — `IntakeRequestDetail` domain entity passed via GoRouter `extra`; diverges from spec

**Location:** `apps/mobile/lib/app/router.dart`, lines 181–196; `apps/mobile/lib/features/beneficiary/presentation/screens/rate_delivery_screen.dart` (ConfirmReceiptScreen constructor)

The router reads `state.extra as IntakeRequestDetail` and passes it to `ConfirmReceiptScreen` as a constructor argument. The spec (SPEC-0008, Screen Layout section) explicitly states:

> "It accepts `batchId` as a constructor parameter; `IntakeRequestDetail` is NOT passed — the provider resolves all needed data."

The implementation passes the full domain entity through the router for one reason: to display `detail.createdAt` on the info tile without issuing a second Firestore read. This is understandable but violates the spec and introduces two problems:

1. **GoRouter deep-link incompatibility.** `extra` is not serialised in the URL. If the user navigates to `/beneficiary/delivery/:batchId/confirm` via a push notification, system back, or external deep link, `state.extra` is `null` and the cast throws `Null check operator used on a null value`, crashing the screen.
2. **Spec contract breach.** The spec deliberately excluded entity passing to keep navigation state stateless and make the screen independently navigable.

**Options:**

| Option | Upside | Downside |
|--------|--------|----------|
| A. Remove `detail` from `ConfirmReceiptScreen`; derive `createdAt` from `watchIntakeRequestDetailProvider` already subscribed on `DeliveryDetailScreen`'s parent route | Spec-compliant; deep-link safe; no second Firestore read because the stream is already cached by Riverpod | Requires a `ref.watch` inside `ConfirmReceiptScreen` to read the detail stream for `createdAt` display only |
| B. Keep `detail` in constructor but make it `IntakeRequestDetail?` and null-handle gracefully | Fixes the crash; simple | Still diverges from spec; `extra` remains unserialised |
| C. Serialise `IntakeRequestDetail` fields into query parameters | Deep-link safe; spec-compliant | Domain entity leaks into URL format; verbose; requires serialisation round-trip |

**Recommendation:** Option A. The `watchIntakeRequestDetailProvider(batchId)` stream is already active in the parent route; accessing it from `ConfirmReceiptScreen` is a single `ref.watch` call that returns a cached value with no extra round-trip to Firestore.

**Reversal cost if Option B chosen instead:** Low — `ConfirmReceiptScreen` can be refactored in isolation. But ADR-0015 and SPEC-0008 must be updated to reflect the deviation.

---

### FINDING-3 — `IntakeStatus.collected` is now unreachable dead code in the mapper

**Location:** `apps/mobile/lib/features/beneficiary/domain/entities/intake_request.dart` (enum); `apps/mobile/lib/features/beneficiary/data/models/intake_request_model.dart` (mapper)

After the enum extension, the mapper routes `'delivered' => IntakeStatus.delivered` and `'closed' => IntakeStatus.closed`. No Firestore string maps to `IntakeStatus.collected` any longer. The value is a dead enum arm. It will not cause a compile error (Dart enums are not sealed in switch expressions unless the switch is exhaustive), but it:

- Misleads future engineers who may assume `collected` is a live status.
- May cause stale tests that construct fixtures with `IntakeStatus.collected` to pass while testing phantom state.

No `collected` references were found in the current test suite (confirmed by search), so the risk is low right now. An ADR for cleanup has been written (`docs/decisions/0017-intake-status-enum-extension.md`). The blocker on this finding is the `pending` fallback arm in the mapper (`_ => IntakeStatus.pending`): an unknown Firestore string now silently becomes `pending` which has no visual treatment in any screen. This should be logged.

**Fix (non-blocking, can be a follow-up PR):** Remove `collected` from the enum and replace the `_ => IntakeStatus.pending` wildcard with `_ => throw StateError('Unknown IntakeStatus: $raw')` or at minimum a logged warning. File a tech debt ticket.

---

### FINDING-4 — File name does not match class name

**Location:** `apps/mobile/lib/features/beneficiary/presentation/screens/rate_delivery_screen.dart`

The spec explicitly calls for "Full replacement with `ConfirmReceiptScreen` implementation; same file path, class renamed to `ConfirmReceiptScreen`." The implementation follows this instruction. However, a file named `rate_delivery_screen.dart` containing a class `ConfirmReceiptScreen` is a permanent maintenance liability:

- `flutter analyze` will not flag it (Dart does not enforce file-name/class-name matching).
- Future engineers searching for `ConfirmReceiptScreen` will not find it by filename.
- The import in `router.dart` reads `import '...rate_delivery_screen.dart'` which is confusing.

This is a spec-compliant implementation of a spec with a debatable decision baked in. The spec should be updated to rename the file to `confirm_receipt_screen.dart` in a follow-up, or the rename should be part of this PR. This is not a blocker by itself but should be flagged as near-term tech debt.

---

### FINDING-5 — `setFeedback` does not enforce the 300-character trim specified in the spec

**Location:** `apps/mobile/lib/features/beneficiary/presentation/providers/confirm_receipt_provider.dart`, line 50–52

The spec states: "`setFeedback`: Updates feedback text; trims to 300 chars." The implementation sets the feedback verbatim without truncation:

```dart
void setFeedback(String value) {
  state = state.copyWith(feedback: value);
}
```

The `TextField` uses `maxLength: 300` which prevents entry beyond 300 characters in the UI, but that is a presentation-layer enforcement only. The spec requires the notifier itself to enforce the cap so that the constraint holds regardless of where `setFeedback` is called (e.g., from tests or future programmatic callers).

**Fix:** `state = state.copyWith(feedback: value.length > 300 ? value.substring(0, 300) : value);`

This is a minor spec divergence, not a blocker, but test case 5 in the spec (`setFeedback trims to 300 chars`) will fail as written.

---

## Spec Compliance Matrix

| Spec requirement | Status |
|-----------------|--------|
| `confirmReceipt` abstract method on `IntakeRepository` | PASS |
| `ConfirmReceiptUseCase` — pure Dart, zero framework imports | PASS |
| `IntakeRemoteDatasource.confirmReceipt` — `beneficiaryId` intentionally omitted | PASS |
| `FirestoreService.confirmReceipt` — partial update with correct fields | PASS |
| `ConfirmReceiptState` fields match spec | PASS |
| `ConfirmReceiptNotifier` family parameter `batchId` | PASS |
| `submit()` in-flight guard | PASS |
| `submit()` reads uid from `authStateProvider` | PASS |
| `ConfirmReceiptScreen` accepts `batchId` only (no entity) | FAIL — entity passed via `extra` |
| `setFeedback` trims to 300 chars | FAIL — not implemented in notifier |
| `_ConfirmReceiptButton` visible when `status == delivered` | PASS |
| `_ConfirmationBanner` visible when `status == closed` | PASS |
| Route `/beneficiary/delivery/:batchId/confirm` added | PASS |
| `confirmReceiptUseCaseProvider` registered in `beneficiary_provider.dart` | PASS |
| All 3 use-case unit tests present | PASS |
| All 11 notifier unit tests present | PASS |
| All 10 widget tests for `ConfirmReceiptScreen` present | PASS |
| All 8 widget tests added to `delivery_detail_screen_test.dart` | PASS |
| `IntakeStatus.delivered` and `IntakeStatus.closed` in mapper | PASS |

---

## Layer Boundary Audit

**`confirm_receipt_usecase.dart`** — imports only `package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart`. Zero Flutter, Riverpod, or Firestore imports. Domain layer constraint satisfied.

**`IntakeRepository.confirmReceipt`** — pure Dart abstract method. No framework leakage.

**`IntakeRequestDetail` entity** — pure Dart with only an intra-domain import of `intake_item.dart` and `intake_request.dart`. Clean.

**`ConfirmReceiptNotifier`** reads `authStateProvider` from `auth/presentation/providers/auth_provider.dart`. This is a cross-feature dependency at the presentation layer, which is explicitly approved by ADR-0016 and SPEC-0008. The domain layer is not involved. Acceptable.

**`FirestoreService.confirmReceipt`** — located in `lib/services/` (data layer equivalent). Uses `FieldValue.serverTimestamp()` and `_firestore.collection(...).doc(...).update(...)`. Contains the syntactic form `'rating': ?rating` (null-aware spread shorthand available in Dart 3.x). This is valid Dart 3 syntax for conditionally including a map entry, equivalent to `if (rating != null) 'rating': rating`. No concern.

---

## Tradeoffs Summary

- **Passing entity via `extra` vs. re-watching the stream:** The `extra` approach avoids one `ref.watch` call but makes the route non-deep-linkable and violates the spec. Re-watching the stream is the architecturally correct path and has negligible cost because the stream is Riverpod-cached.
- **`copyWith` sentinel vs. Freezed:** Using a sentinel constant is low-overhead and does not require adding `freezed` as a dependency for this class. Alternatively, the team could use the existing `Freezed` pattern already in the data layer models. Either is acceptable; consistency with other non-Freezed notifier states in the codebase is the deciding factor.
- **`collected` cleanup now vs. later:** Removing `collected` in this PR reduces enum surface area but increases the diff size. Deferring is the pragmatic choice given it carries no runtime risk today.

---

## Verdict

**CHANGES REQUESTED**

Two blockers must be resolved before merge: the `copyWith` bug that silently discards error state on every star tap and keystroke (BLOCKER-1), and the `IntakeRequestDetail` entity passed via `state.extra` in the router in violation of the spec and causing a deep-link crash (BLOCKER-2). All other findings are non-blocking follow-ups. Re-submit for architect review after both blockers are addressed.
