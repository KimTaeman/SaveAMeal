# QA Review — 2026-06-04 — confirm-receipt

**Reviewer:** qa-engineer  
**Session ID:** qa-confirm-receipt  
**PR / Branch:** feat/confirm-receipt  
**Date:** 2026-06-04

---

## Summary

Reviewed the `feat/confirm-receipt` branch (+2252/-103, 27 files) implementing SPEC-0008: beneficiary confirm-receipt flow. The PR introduces `ConfirmReceiptUseCase`, `ConfirmReceiptNotifier`, `ConfirmReceiptScreen` (replacing the `RateDeliveryScreen` stub), and `_ConfirmReceiptButton` / `_ConfirmationBanner` additions to `DeliveryDetailScreen`. All 357 tests pass (zero failures, zero skips). `flutter analyze` reports no issues. One bug is present in `ConfirmReceiptState.copyWith` that silently clears `error` on every mutation call; no test covers the `uid == null` auth-guard path; three accessibility gaps exist in `ConfirmReceiptScreen`; and the decorative icon in `_ConfirmationBanner` lacks `ExcludeSemantics`. Verdict: CHANGES REQUESTED.

---

## Test Results

- **Total tests:** 357 passed, 0 failed, 0 skipped
- **New confirm-receipt tests:** 36 (3 use-case unit + 11 notifier unit + 10 screen widget + 8 delivery-detail widget + 1 rate-delivery stub placeholder + 3 pre-existing status-mapper tests updated)
- **Regressions from IntakeStatus enum extension:** none — all pre-existing tests pass unchanged
- **`flutter analyze`:** zero issues

### Coverage against the spec matrix

| Case | File | Present |
|---|---|---|
| UC-1 delegates to repo with exact args | confirm_receipt_usecase_test.dart | yes |
| UC-2 propagates exception | confirm_receipt_usecase_test.dart | yes |
| UC-3 null rating/feedback when omitted | confirm_receipt_usecase_test.dart | yes |
| N-1 initial state | confirm_receipt_notifier_test.dart | yes |
| N-2 setRating(3) sets 3 | confirm_receipt_notifier_test.dart | yes |
| N-3 setRating toggle deselects | confirm_receipt_notifier_test.dart | yes |
| N-4 setRating changes value | confirm_receipt_notifier_test.dart | yes |
| N-5 setFeedback | confirm_receipt_notifier_test.dart | yes |
| N-6 submit isSubmitting true→false | confirm_receipt_notifier_test.dart | yes |
| N-7 submit sets submitted=true | confirm_receipt_notifier_test.dart | yes |
| N-8 submit error path | confirm_receipt_notifier_test.dart | yes |
| N-9 double-submit guard | confirm_receipt_notifier_test.dart | yes |
| N-10 zero rating → null arg | confirm_receipt_notifier_test.dart | yes |
| N-11 empty feedback → null arg | confirm_receipt_notifier_test.dart | yes |
| **N-12 uid==null auth guard** | confirm_receipt_notifier_test.dart | **MISSING** |
| W-1 title/subtitle | confirm_receipt_screen_test.dart | yes |
| W-2 5 star unfilled | confirm_receipt_screen_test.dart | yes |
| W-3 star tap fills | confirm_receipt_screen_test.dart | yes |
| W-4 star tap deselects | confirm_receipt_screen_test.dart | yes |
| W-5 CTA present | confirm_receipt_screen_test.dart | yes |
| W-6 CTA disabled + spinner when submitting | confirm_receipt_screen_test.dart | yes |
| W-7 pops on submitted | confirm_receipt_screen_test.dart | yes |
| W-8 snackbar on error | confirm_receipt_screen_test.dart | yes |
| W-9 Report an Issue present | confirm_receipt_screen_test.dart | yes |
| W-10 order# tile | confirm_receipt_screen_test.dart | yes |
| D-1 button visible for delivered | delivery_detail_screen_test.dart | yes |
| D-2 button absent for open | delivery_detail_screen_test.dart | yes |
| D-3 button absent for dispatched | delivery_detail_screen_test.dart | yes |
| D-4 button absent for cancelled | delivery_detail_screen_test.dart | yes |
| D-5 button absent for closed | delivery_detail_screen_test.dart | yes |
| D-6 navigates on tap | delivery_detail_screen_test.dart | yes |
| D-7 banner shown for closed | delivery_detail_screen_test.dart | yes |
| D-8 banner absent for non-closed | delivery_detail_screen_test.dart | yes |

---

## Findings

### Critical (block merge)

- **`ConfirmReceiptState.copyWith` error field is always unconditionally overwritten.** `copyWith` assigns `error: error` directly (line 32 of `confirm_receipt_provider.dart`) rather than using `error ?? this.error`. This means every call to `setRating`, `setFeedback`, or the success path of `submit` (which does `copyWith(submitted: true, isSubmitting: false)` without passing `error`) will silently clear a previously-set error string. The `submit` success path is currently coincidentally correct (error should be cleared) but `setRating` and `setFeedback` silently clear errors, which is unexpected. The `submit` success state also relies on `error` defaulting to null rather than explicitly communicating intent. Correct pattern uses a sentinel (e.g., `Object? error = _sentinel`) or a `clearError` flag.

  Required fix: use the standard null-sentinel pattern so `error` is only cleared when the caller explicitly passes `null`:

  ```dart
  static const _unset = Object();
  ConfirmReceiptState copyWith({
    int? rating,
    String? feedback,
    bool? isSubmitting,
    Object? error = _unset,
    bool? submitted,
  }) => ConfirmReceiptState(
    rating: rating ?? this.rating,
    feedback: feedback ?? this.feedback,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: identical(error, _unset) ? this.error : error as String?,
    submitted: submitted ?? this.submitted,
  );
  ```

### High (fix before release)

- **Missing test: `uid == null` auth-guard path in `ConfirmReceiptNotifier.submit`.** The notifier handles the case where `authStateProvider` emits `null` by setting `error: 'Not authenticated'` and returning early (lines 60-63 of `confirm_receipt_provider.dart`). No test in `confirm_receipt_notifier_test.dart` verifies this branch. Every regression test suite requires a path for the auth-null guard. Required fix: add a unit test using `_makeContainer(fakeRepo, user: null)` and verify `state.error == 'Not authenticated'` and `state.isSubmitting == false` after `submit()`.

- **`_ConfirmationBanner` decorative icon missing `ExcludeSemantics`.** The `Icons.check_circle` in `_ConfirmationBanner` is purely decorative (the adjacent `Text('Receipt confirmed')` carries the full meaning). Without `ExcludeSemantics`, TalkBack/VoiceOver will announce a redundant icon description before the text. Required fix: wrap the `Icon` in `ExcludeSemantics(child: Icon(...))`.

### Informational

- **`ConfirmReceiptScreen` star `IconButton` widgets have no semantic labels.** Each `IconButton` in the star row has no `tooltip` and the `icon` has no `semanticLabel`. Screen readers will announce all five as identical interactive elements with no distinguishable label. Recommended fix: add `tooltip: 'Rate $starValue out of 5 stars'` to each `IconButton`.

- **`ConfirmReceiptScreen` feedback `TextField` has no `labelText`.** The `InputDecoration` uses only `hintText`; a `labelText` is required for WCAG 2.2 AA (Success Criterion 1.3.5 — Identify Input Purpose). Recommended fix: add `labelText: 'Feedback'` to the `InputDecoration`.

- **`_ConfirmReceiptButton` icon has no semantic label.** The `Icon(Icons.check_circle_outline)` inside `FilledButton.icon` has no `semanticLabel`. The button text `'Confirm Receipt'` is present and may be sufficient for most platforms, but adding `semanticLabel: ''` to the icon (to mark it decorative) is explicit best practice. Low risk.

- **`IntakeStatus.collected` is now a dead enum value.** The `mapIntakeStatus` switch no longer maps any raw string to `IntakeStatus.collected` (previously `'delivered'` and `'closed'` mapped to it). The enum value remains in the entity but is unreachable from data-layer parsing. This is not a bug in this PR (the change is intentional for the new state machine), but the value should either be removed or documented as reserved. No test references it.

- **`rate_delivery_screen_test.dart` is an empty placeholder.** The file contains a `main()` with no tests and a comment pointing to `confirm_receipt_screen_test.dart`. This is acceptable given the screen was replaced, but the file should be deleted rather than left as a zero-test stub to avoid confusing future contributors.

- **No golden tests added.** Per the QA quality gate, every new screen requires a golden test at text scales 1.0 and 1.5. `ConfirmReceiptScreen` has no golden tests. This is a process gap, not a functional defect, but must be addressed before the release milestone.

---

## Checklist

- [x] `flutter analyze` passes with zero issues
- [x] `dart format` — no diff (analyze confirms formatting)
- [x] All new screens have widget tests (`ConfirmReceiptScreen`, `DeliveryDetailScreen` additions)
- [x] No new unbounded `ListView` usage — `ConfirmReceiptScreen` uses `SingleChildScrollView` + `Column`, not `ListView`
- [x] No remote images — no `CachedNetworkImage` required
- [x] `IntakeStatus.claimed` and `IntakeStatus.pickedUp` still map to `IntakeStatus.dispatched` — confirmed in `intake_request_model.dart` lines 14-15 and all related tests pass
- [x] `IntakeStatus.dispatched`-dependent tests (active_delivery_card_test, delivery_detail_screen dispatched cases) pass unchanged
- [ ] Semantic labels present on all interactive widgets — FAIL: star `IconButton` widgets lack `tooltip`; feedback `TextField` lacks `labelText`
- [x] Text contrast — no hardcoded colors; all colors from `AppColors` / `ColorScheme`
- [ ] Golden tests at scale 1.0 and 1.5 for `ConfirmReceiptScreen` — MISSING
- [ ] `ConfirmReceiptState.copyWith` error sentinel pattern — FAIL: unconditional overwrite
- [ ] Auth-null guard test — MISSING

---

## Verdict

**CHANGES REQUESTED**

Two required fixes before merge: (1) the `copyWith` error-field sentinel bug in `confirm_receipt_provider.dart` — `setRating` and `setFeedback` silently clear errors in the current implementation; (2) a unit test covering the `uid == null` auth-guard branch in `ConfirmReceiptNotifier.submit`. The accessibility gaps (star labels, TextField label, decorative icon exclusion) and missing golden tests must be addressed before the release milestone per the quality gate checklist.
