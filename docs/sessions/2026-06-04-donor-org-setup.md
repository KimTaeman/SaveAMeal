# Session: 2026-06-04 — donor-org-setup

**Date:** 2026-06-04  
**Member:** KimTaeman  
**Agent:** flutter-engineer  
**Task:** Add donor organization profile onboarding step after account registration

---

## Context

After a donor registers (handled by `RegisterScreen` + `SignUpUsecase`), they land on `/donor` via `RoleRouterScreen`. No organization profile info is collected during registration — `DonorProfile.orgName` is `null` for all new donors. The `OrganizationProfileScreen` exists at `/donor/account/org` but is only reachable after reaching the dashboard.

The task is to intercept new donors (orgName == null) and route them to an onboarding screen to fill in their organization details before reaching the dashboard.

## Plan

1. Create `DonorOrgSetupScreen` at `features/donor/presentation/screens/` — step-2-of-2 onboarding form (org name required; manager, phone, address, surplus types optional)
2. Add `/donor/onboarding` route to `router.dart`
3. Modify `RoleRouterScreen._routeByRole` to await `currentUserProvider` for donors and redirect to `/donor/onboarding` if `orgName` is null/empty
4. Create widget test at `test/widget/features/donor/donor_org_setup_screen_test.dart`

## Progress

- [x] `DonorOrgSetupScreen` created
- [x] Route `/donor/onboarding` added to `router.dart`
- [x] `RoleRouterScreen._routeByRole` made async with profile check
- [x] Widget test created (13 cases)

## Decisions Made

- `_routeByRole` is now `Future<void>` — `whenData` discards the return value, fire-and-forget is safe
- Donor re-routing logic lives in `RoleRouterScreen` rather than a router redirect because GoRouter's `redirect` is synchronous and `currentUserProvider` is async
- "Skip for now" navigates to `/donor` without saving — next login will show onboarding again until orgName is set
- Operating hours excluded from onboarding form (complex UI; available in account settings)

## Blockers / Open Questions

- None

## Handoff

QA: test the full registration → onboarding → dashboard flow on device. Verify "Skip for now" works and onboarding re-appears on next login if skipped. Also verify existing donors (orgName already set) are routed directly to `/donor` without seeing onboarding.

**Review needed from:** qa-engineer
