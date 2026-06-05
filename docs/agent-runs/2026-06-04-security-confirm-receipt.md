# Security Review — 2026-06-04 — confirm-receipt

**Reviewer:** security-reviewer
**Session ID:** confirm-receipt
**PR / Branch:** feat/confirm-receipt → main
**Date:** 2026-06-04
**Files reviewed:** 27 changed files (+2252 / −103)
**Spec:** `tech-specs/0008-confirm-receipt.md`

---

## Summary

This diff adds the beneficiary-side "Confirm Receipt" flow: a new `ConfirmReceiptScreen`, a Riverpod notifier that reads `uid` from `authStateProvider`, a `ConfirmReceiptUseCase`, and the corresponding data-layer plumbing down to `FirestoreService.confirmReceipt`. The Firestore rule for the beneficiary batch update was changed from `keys().hasOnly(...)` to `diff(resource.data).affectedKeys().hasOnly(...)`, which is the correct semantic fix. The identity resolution strategy (uid from `authStateProvider`, never from URL params or loaded entity) is implemented as designed in ADR-0016.

No plaintext secrets were introduced in any of the 27 changed files. The `firestore.rules` change is security-positive. There are four security-relevant items below; none rise to Critical, but two are High and must be fixed before release.

## Findings

### Critical (block merge)

None.

### High (fix before release)

- **No server-side `rating` range validation in Firestore rules** (`firestore.rules` line 66) — the rule permits a beneficiary to write any integer to `rating`. The UI star row generates 1–5 and `rating == 0` is mapped to `null` before reaching Firestore, but a raw SDK call can write `rating: -999` or `rating: 999999` to any owned batch. A rogue value could corrupt analytics, break star-display in future donor-facing views, or exploit downstream processing that assumes a 1–5 range. Risk: CWE-20 / CWE-602. Required fix: add to the beneficiary update arm `&& (!('rating' in request.resource.data.diff(resource.data).affectedKeys()) || (request.resource.data.rating is int && request.resource.data.rating >= 1 && request.resource.data.rating <= 5))`.

- **No server-side `feedback` length enforcement in Firestore rules** (`firestore.rules` line 66) — the `TextField` `maxLength: 300` is a Flutter widget constraint bypassable by raw SDK calls. The `setFeedback` notifier method does not enforce the cap either (noted by architect as FINDING-5). A beneficiary can write an arbitrarily long string to `feedback`, consuming unbounded storage and violating the ≤ 300 character contract assumed by any future display or processing pipeline. Risk: CWE-20 / CWE-770. Required fix: add to the rule `&& (!('feedback' in request.resource.data.diff(resource.data).affectedKeys()) || request.resource.data.feedback.size() <= 300)`. Also add the notifier-level truncation: `value.length > 300 ? value.substring(0, 300) : value` as defence-in-depth.

### Informational

- **`diff(resource.data).affectedKeys().hasOnly()` rule change is a security improvement.** The previous `keys().hasOnly(...)` form checked all keys in the resulting document against the allowlist, which would always fail for a document with unrelated fields. The `diff().affectedKeys()` form is semantically correct and more restrictive: only the fields being changed are checked. No bypass path was opened by this change.

- **`beneficiaryId` resolution is correctly anchored to `authStateProvider`.** `ConfirmReceiptNotifier.submit()` reads `uid` from `ref.read(authStateProvider).asData?.value?.uid`. The Firestore rule independently enforces `resource.data.beneficiaryId == uid()`, providing a second independent ownership check. Even if a caller passed a forged `beneficiaryId` argument, the rule would reject the write. ADR-0016 decision is correctly implemented.

- **`state.extra as IntakeRequestDetail` in the router does not introduce privilege escalation.** The `batchId` from the URL path parameter drives the actual Firestore write; the `extra` object is used only for display. The crash risk on null `extra` (deep link / back-navigation) is covered by the architect's BLOCKER-2 and is a denial-of-service risk, not an authorisation risk.

- **`watchIntakeRequestDetail` enforces client-side ownership** at `firestore_intake_repository.dart` line 83 (`if (batch.beneficiaryId != beneficiaryId) return null`). Combined with the Firestore rule's ownership check, ownership is enforced at two independent layers.

- **Re-confirm on already-closed batch is permitted by the rule.** The rule allows beneficiary writes when `resource.data.status in ['delivered', 'closed']`, meaning an authenticated beneficiary can overwrite `rating`/`feedback` on a batch they already closed via a raw SDK call. The UI suppresses the button when `status == closed`, so this is not reachable through the normal flow. If rating immutability is a business requirement, tighten the rule to `status == 'delivered'` only. Acceptable for MVP but should be documented.

- **Firebase API keys in `firebase_options.dart` predate this branch and were not modified in this diff.** They are Firebase client-identifying keys (not admin credentials), but they are committed in plaintext in violation of the project's `CLAUDE.md` "no plaintext secrets" convention. This is a pre-existing issue and is out of scope for this review. A separate remediation ticket is recommended.

- **Secret scan result: clean for this diff.** No API keys, bearer tokens, private keys, or hardcoded passwords were found in any of the 27 changed files. The scan covered all changed Dart source files, the Firestore rules file, and documentation files.

- **`e.toString()` surfaced to the UI in `ConfirmReceiptNotifier`** (`confirm_receipt_provider.dart` line 78). Firestore error messages shown verbatim in a `SnackBar` may disclose internal document paths or field names. Low severity in a mobile client context, but worth noting as an information disclosure vector (CWE-209).

- **Unknown Firestore status values silently map to `IntakeStatus.pending`** via the `_ => IntakeStatus.pending` wildcard in `mapIntakeStatus`. This masks data integrity anomalies. Recommend replacing with a logged warning or a `StateError` in a follow-up PR.

## Checklist

- [x] No API keys or backend config hardcoded in the 27 changed `.dart` files
- [x] Sensitive values not introduced via this diff
- [ ] Firebase API keys in `firebase_options.dart` committed in plaintext — pre-existing issue, out of scope for this diff
- [x] `.env` files are gitignored (`.env` and `.env.*` present in `.gitignore`)
- [x] No `flutter_secure_storage` needed — no credential persistence introduced by this feature
- [x] `beneficiaryId` sourced from `authStateProvider`, not URL params or GoRouter `extra`
- [x] Firestore ownership guard (`resource.data.beneficiaryId == uid()`) present in rules
- [x] Firestore status guard (`status in ['delivered','closed']`) present in rules
- [x] Field allowlist (`affectedKeys().hasOnly([...])`) present in rules
- [ ] Server-side `rating` range validation missing from Firestore rules (HIGH)
- [ ] Server-side `feedback` length validation missing from Firestore rules (HIGH)

## Verdict

**CHANGES REQUESTED**

Two High findings must be resolved before release: missing server-side range validation for `rating` and missing server-side length enforcement for `feedback` in the Firestore rules — both fields are client-validated only and bypassable by any authenticated beneficiary with direct SDK access.
