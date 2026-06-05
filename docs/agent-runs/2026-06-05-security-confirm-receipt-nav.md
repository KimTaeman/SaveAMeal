# Security Review — 2026-06-05 — feat/confirm-receipt (nav fixes)

**Reviewer:** security-reviewer
**Session ID:** confirm-receipt-nav
**PR / Branch:** feat/confirm-receipt
**Date:** 2026-06-05

---

## Summary

This review covers the navigation-hardening commits added on top of the already-reviewed SPEC-0008 confirm-receipt feature. The specific changes examined are: (1) the `_normalise()` wrapper applied to three previously-unpatched `BatchModel.fromJson()` call sites in `firestore_service.dart`; (2) the upgrade of `BeneficiaryBottomNav` from a `StatelessWidget` to a `ConsumerWidget` that watches `authStateProvider` and `activeDeliveriesProvider(uid)` for dynamic Track-tab routing; (3) removal of dead `onDestinationSelected` overrides across six beneficiary screen files; (4) addition of `BeneficiaryBottomNav` scaffolding to three screens that were missing it; and (5) the restructuring of `RecentDeliveriesSection` including a navigation change from `context.push` to `context.go` on "View All" and a new `onTap` that routes to `/beneficiary/delivery/:batchId`. No new secrets, API keys, or credentials were introduced. The overall posture is good. Two medium-severity issues and two informational notes are raised; none of the findings block the merge.

---

## Findings

### Critical (block merge)

None.

### High (fix before release)

None.

### Medium (fix soon — not a merge blocker)

- **Empty-UID Firestore query from unauthenticated state** — `BeneficiaryBottomNav` (`beneficiary_bottom_nav.dart` line 19-21) reads `uid` as `authStateProvider.asData?.value?.uid ?? ''`. If `authStateProvider` is loading or its value is null — which can occur briefly on cold start before Firebase restores the session, or if the widget is mounted in a test without an authenticated user — `activeDeliveriesProvider('')` is invoked with an empty string. The Firestore query in `watchActiveDeliveriesForBeneficiary` then executes `.where('beneficiaryId', isEqualTo: '')`, which will match no documents (an empty string is not a valid UID) and return an empty list, so no foreign data is leaked. However, the unauthenticated network round-trip is wasted work and may generate a Firestore permission-denied error that bubbles up as an unhandled stream error. Recommended fix: guard with `if (uid.isEmpty) return const Stream.empty();` inside the provider, or skip the watch entirely when `authStateProvider` is not yet in `AsyncData` state. CWE-303 (Incorrect Implementation of Authentication Algorithm — allowing degraded-auth path to reach authenticated endpoints).

- **`batchId` used directly in a GoRouter path with no sanitisation** — `beneficiary_bottom_nav.dart` line 34 constructs `'/beneficiary/delivery/${deliveries.first.batchId}'` from data sourced directly from a Firestore document. `recent_deliveries_section.dart` (new `onTap`) does the same. GoRouter's `context.go` and `context.push` perform no URI encoding on the interpolated segment. If `batchId` ever contains a `/` character — possible if a Firestore document ID were crafted or corrupted — it would silently add an extra path segment and land on an unintended route (e.g., `/beneficiary/delivery/foo/bar` matches the nested `/confirm` child route). Firestore auto-generated IDs are alphanumeric and never contain `/`, so the practical risk is low in this stack. The recommended fix is defensive: call `Uri.encodeComponent(batchId)` at the interpolation site, or assert in the domain entity constructor that `batchId` contains only expected characters. CWE-20 (Improper Input Validation).

### Informational

- The `/driver` routes in `router.dart` lack the role-guard redirect (`user.role != UserRole.driver => '/role-router'`) that the `/donor` and `/beneficiary` parent routes both have. This is pre-existing and outside this diff's scope, but it means a beneficiary or donor who manually navigates to a `/driver/*` deep-link is not redirected by the router (they would be stopped by Firestore rules). Recommended to add the guard in a follow-up to maintain defence-in-depth.

- `confirmReceipt` in `firestore_service.dart` (line 548) uses the Dart null-aware spread operator `?rating` as a map entry value, which is not standard Dart syntax (`'rating': ?rating` is not valid — the null-aware spread `...?map` is valid but `value: ?expr` is not). If this compiles it may be relying on an unreleased language feature or the line is a transcription error in the diff. Regardless, it is not a security concern but warrants a compile-time verification to ensure the `rating` field is correctly omitted (not written as `null`) when no rating is provided, because the Firestore security rule for the beneficiary update path uses `diff().affectedKeys().hasOnly([...])` and a `null` write to `rating` would include `rating` in the affected keys and break the rule.

---

## Checklist

- [x] No API keys, Firebase service-account credentials, or other secrets hardcoded in any `.dart` file in the diff
- [x] `flutter_secure_storage` pattern not affected by this diff (no new credential persistence)
- [x] `_normalise()` function only transforms `Timestamp` → ISO-8601 string and recurses into nested maps/lists; it does not read, log, or forward any field values
- [x] Firestore Security Rules enforce server-side ownership for all batch writes — the beneficiary update rule requires `resource.data.beneficiaryId == uid()` and restricts affected keys to `[status, rating, feedback, updatedAt]`
- [x] `intakeRequestDetail` provider performs a client-side ownership check (`batch.beneficiaryId != beneficiaryId → return null`) in addition to the Firestore rule
- [x] GoRouter `/beneficiary` parent route has a redirect guard checking both authentication (`user == null`) and role (`user.role != UserRole.beneficiary`) — unauthenticated users cannot reach beneficiary nav at all via normal routing
- [x] `context.go('/beneficiary/history')` (replacing `context.push`) on "View All" is a nav-stack correctness change, not a security concern
- [x] No new third-party packages introduced in this diff
- [x] `.env` / secrets files not present or staged

---

## Verdict

**APPROVED**

Reason: No critical or high findings; both medium issues have a safe fallback enforced by Firestore Security Rules server-side, making them defence-in-depth gaps rather than exploitable vulnerabilities, and neither warrants blocking the merge.
