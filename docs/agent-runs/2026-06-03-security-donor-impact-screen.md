# Security Reviewer Review — 2026-06-03 — donor-impact-screen

**Reviewer:** security-reviewer
**Session ID:** donor-impact-screen
**PR / Branch:** feature/donor-impact-screen
**Date:** 2026-06-03

---

## Summary

Reviewed the `DonorImpactScreen` addition (`donor_impact_screen.dart`, 357 lines), the corresponding router change in `router.dart`, the cleanup of orphaned code in `beneficiary_dashboard_screen.dart`, and the widget test suite (`donor_impact_screen_test.dart`, 247 lines). The screen is a read-only analytics view that sources the authenticated uid exclusively from `authStateProvider`, passes it to `donorMetricsProvider(uid)` and `activeBatchesProvider(uid)`, and renders aggregated stats with no writes or user input. No plaintext secrets or debug leaks were found in the changed files. One medium-severity cross-role navigation gap and two informational items (hardcoded colours, a test assertion that will always fail) were identified. The overall verdict is CHANGES REQUESTED pending resolution of the role-boundary finding.

## Findings

### Critical (block merge)
_None._

### High (fix before release)

- **Cross-role route access — no role guard on `/donor/impact`** (`apps/mobile/lib/app/router.dart`, lines 92–94) → A beneficiary or driver who is authenticated can deep-link or type `/donor/impact` and reach the screen; the GoRouter redirect (lines 40–47) only blocks unauthenticated users, it does not enforce that the current user holds `UserRole.donor`. Inside the screen, `uid` is taken from `authStateProvider` (correct), so Firestore data returned would be that user's own batches — but the screen renders donor-specific UI to a non-donor user, violating the role boundary. CWE-285 (Improper Authorization). Required fix: add a `redirect` callback on the `/donor` parent route (or on each child) that checks `user.role == UserRole.donor` and redirects to `/role-router` otherwise, matching the pattern already used for unauthenticated users.

### Informational

- **Hardcoded hex colours throughout `donor_impact_screen.dart`** (lines 41, 46, 91, 225, 239, 315, 325, 342, 350 — `Color(0xFF006E2F)`, `Color(0xFF22C55E)`) and hardcoded `Colors.white` (lines 37, 101, 114, 122, 136, 138, 149, 194, 312). CLAUDE.md forbids hardcoded colours; all values must come from `cs.*` or `ac.*`. This is a code-quality violation, not a security defect, but it is flagged for completeness.

- **Test case 6 ("No donations yet") will always fail** (`apps/mobile/test/widget/features/donor/donor_impact_screen_test.dart`, lines 193–217). The string `'No donations yet'` does not exist anywhere in `donor_impact_screen.dart`. The screen renders a fixed category list (Fruits & Veggies, Bakery, Prepared Meals, Dairy) at 0% when batches is empty — there is no empty-state widget emitting that text. This is a QA concern rather than a security finding, but a permanently-failing test erodes confidence in the test suite and should be corrected before merge.

## Checklist

- [x] No API keys, tokens, or credentials hardcoded in any `.dart` file reviewed
- [x] No `print()` or `debugPrint()` calls in `donor_impact_screen.dart`
- [x] `AppLogger` gates all output behind `kDebugMode` — no PII leaked in release builds
- [x] `uid` sourced exclusively from `authStateProvider`, not from route parameters or `extra`
- [x] `donorMetricsProvider(uid)` and `activeBatchesProvider(uid)` receive the auth-derived uid — a donor cannot fabricate another donor's uid via the UI
- [x] Firestore queries in `watchDonorMetrics` and `watchActiveBatchesForDonor` filter by `donorId` — server-side scope is correct assuming Firestore Security Rules enforce `request.auth.uid == donorId` (rules file not in scope of this PR, noted as assumption)
- [x] Screen is strictly read-only — no writes, no form submissions, no side effects
- [x] Notification bell navigates via `context.push('/notifications')` — `/notifications` is inside the authenticated router tree; the global redirect guard ensures the user is authenticated before reaching it
- [x] `google-services.json` and `GoogleService-Info.plist` are gitignored (confirmed via `.gitignore` lines 58–59)
- [x] No `.env` files committed
- [ ] Role guard missing on `/donor` subtree (see High finding above)
- [ ] Test case 6 assertion does not match screen output (see Informational note above)

## Verdict

**CHANGES REQUESTED**

Reason: A missing role guard on the `/donor/impact` route allows any authenticated non-donor user to reach a donor-only screen; add a role-based redirect before merging.
