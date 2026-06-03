# QA Review (v2) — 2026-06-03 — donor-account-screens

**Reviewer:** qa-engineer
**Session ID:** donor-account-screens-v2
**PR / Branch:** feature/donor-account-screens
**Date:** 2026-06-03

---

## Summary

Re-review of the donor account feature (DonorAccountScreen, PersonalInformationScreen, OrganizationProfileScreen) after CHANGES REQUESTED from v1. Both failing tests are now confirmed fixed by static analysis. The notification-bell tooltip is present on all three AppBars. The `UserProfileUpdate` typed entity is in place and all three fake repositories implement the correct signature. However, five of the six originally-requested test scenarios remain absent from the test files, the photo-upload `GestureDetector` still carries no accessibility wrapper, and bell-navigation is untested. Two new observations were added for the `_save` error-path in OrganizationProfileScreen and an unregistered `/notifications` route in the widget-test routers.

---

## Findings

### Critical (block merge)
- None.

### High (fix before release)

**H1 — Five missing test scenarios still absent (carried from v1, still open)**

The following test scenarios were required in v1 and are confirmed absent by reading all three test files:

- `personal_information_screen_test.dart`: no test tapping Save with valid data and asserting the 'Saved' SnackBar appears.
- `personal_information_screen_test.dart`: no test for the error path (fake repo throws, SnackBar shows error message).
- `donor_account_screen_test.dart`: no test tapping "Log Out" and verifying `signOut` is called (or navigation changes).
- `organization_profile_screen_test.dart`: no test tapping the edit pencil in the Operating Hours card, verifying text fields appear, and tapping Done to return to view mode.
- `personal_information_screen_test.dart`: no test verifying the photo-upload tap target is present as a `Semantics` node (the photo upload stub).

Required fix: add all five tests. The save happy/error paths require a `_CapturingFakeDonorAccountRepository` variant that tracks whether `updateUser` was called and can be configured to throw.

**H2 — Photo-upload `GestureDetector` has no Semantics wrapper (carried from v1, still open)**

`personal_information_screen.dart` lines 123–180: the `GestureDetector` wrapping the avatar circle and "Upload Photo" label has no `Semantics` ancestor and no `tooltip`. Screen readers emit nothing when focus reaches this tap target.

Required fix:

```dart
Semantics(
  label: 'Upload profile photo',
  button: true,
  child: GestureDetector(
    onTap: _pickImage,
    ...
  ),
)
```

### Medium

**M1 — Bell-icon navigation untested (new)**

All three AppBars now call `context.push('/notifications')` on the bell tap. The widget-test routers in all three test files do not register a `/notifications` route. If a test ever taps the bell, GoRouter will throw a `GoException` and the test will crash rather than pass. More importantly, no test verifies that tapping the bell actually navigates to `/notifications`, which is now production behaviour.

Required fix: add a `/notifications` stub route to each `_buildRouter()` helper, then add one test per screen that taps the bell and asserts the stub screen appears. Minimum: one test in `donor_account_screen_test.dart` since the other two screens reuse the same pattern.

**M2 — `_save` error-path SnackBar message discrepancy in OrganizationProfileScreen (new)**

`organization_profile_screen.dart` `_save()` catch block (lines 169–179) shows `'Upload failed. Please try again.'` for a `FirebaseException` — the same string used by the banner-upload path. The correct message for a save failure should read `'Save failed. Please try again.'` to distinguish the two operations for the user. This would be caught immediately if an error-path save test existed.

Recommended fix: change the `_save` catch message to `'Save failed. Please try again.'` and add the error-path test to verify it.

### Informational

**I1 — `withOpacity` deprecation (carried advisory from v1)**

`organization_profile_screen.dart` line 762 uses `_kGreen.withOpacity(0.15)` with a `// ignore: deprecated_member_use` suppression. The fix (`withValues(alpha: 0.15)`) is a one-line change; the suppress comment is acceptable short-term but should be resolved before production.

**I2 — `UserProfileUpdate.toMap()` included but unused in domain entity (informational)**

`user_profile_update.dart` exposes a `toMap()` method. Domain entities should be pure value objects; serialization belongs in the data layer. The method is not currently called from within the domain layer, so it does not break the boundary, but it is a maintenance hazard. Recommend moving `toMap()` to the repository implementation or a mapper class before production.

**I3 — No golden tests for any donor screen (carried advisory from v1)**

Zero golden tests exist for all three donor screens. Required before production per project quality gate (one golden per screen at text scale 1.0 and 1.5).

---

## Checklist

- [x] `Icons.camera_alt` used in source — test now matches (`Icons.camera_alt`)
- [x] `'Monday–Friday'` (en-dash U+2013) confirmed in both source and test
- [x] `UserProfileUpdate` typed entity exists at `domain/entities/user_profile_update.dart`
- [x] All three fake repositories implement `updateUser(String uid, UserProfileUpdate update)` — compile-safe
- [x] Notification bell `tooltip: 'Notifications'` present on all three AppBars
- [x] `ListView.builder` with `itemCount: 1` used in all three screens — no unbounded ListViews
- [x] All remote images use `CachedNetworkImage`
- [x] `/notifications` route registered in the main app router (`router.dart` line 170)
- [ ] Photo-upload `GestureDetector` has no `Semantics` wrapper — OPEN
- [ ] Happy-path save test (PersonalInformationScreen) — MISSING
- [ ] Error-path save test (PersonalInformationScreen) — MISSING
- [ ] Log-out flow test (DonorAccountScreen) — MISSING
- [ ] Operating-hours edit-mode test (OrganizationProfileScreen) — MISSING
- [ ] Photo-upload accessibility/stub test (PersonalInformationScreen) — MISSING
- [ ] Bell navigation tested and `/notifications` stub route in test routers — MISSING
- [ ] Golden tests — MISSING (advisory, required before production)

---

## Resolution Table

| Finding | Previous Status | Current Status | Action Required |
|---------|----------------|----------------|-----------------|
| Failing test: `Icons.camera_alt_outlined` | HIGH / FAILING | RESOLVED | None |
| Failing test: `'Monday – Friday'` (wrong dash) | HIGH / FAILING | RESOLVED | None |
| `UserProfileUpdate` typed entity instead of Map | NEW in this pass | RESOLVED | None |
| Notification bell missing tooltip | MEDIUM / OPEN | RESOLVED | None |
| Happy-path save test missing | HIGH / OPEN | STILL OPEN | Add test |
| Error-path save test missing | HIGH / OPEN | STILL OPEN | Add test |
| Log-out flow test missing | HIGH / OPEN | STILL OPEN | Add test |
| Operating-hours edit-mode test missing | HIGH / OPEN | STILL OPEN | Add test |
| Photo-upload stub/accessibility test missing | HIGH / OPEN | STILL OPEN | Add test |
| Photo-upload `GestureDetector` no Semantics | MEDIUM / OPEN | STILL OPEN | Add `Semantics` wrapper |
| Bell navigation untested, route not in test router | — | NEW MEDIUM | Add stub route + test |
| `_save` error SnackBar wrong message (OrgProfile) | — | NEW MEDIUM | Fix message + test |
| `withOpacity` deprecation | LOW / ADVISORY | STILL OPEN | Fix before production |
| Golden tests absent | LOW / ADVISORY | STILL OPEN | Required before production |
| `toMap()` in domain entity | — | NEW INFORMATIONAL | Move to data layer |

---

## Verdict

**CHANGES REQUESTED**

The two previously-failing tests are fixed and the typed domain entity is correctly introduced — good progress. However, five of the six mandatory test scenarios from v1 remain unwritten, the photo-upload tap target is still inaccessible to screen readers, and the newly-introduced bell navigation is not covered by any test and will crash tests if the bell is ever tapped. These gaps must be closed before the PR can be approved.

**Signed off:** qa-engineer, 2026-06-03
