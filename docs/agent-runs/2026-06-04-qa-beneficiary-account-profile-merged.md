# PR Review — feat/beneficiary-profile (Beneficiary Account & Profile)
Date: 2026-06-04
Branch: feat/beneficiary-profile
Requested by: NichapaJongKmutt

---

## Overall Verdict: CHANGES REQUESTED

Seven blocking findings across three reviewers. No finding is CRITICAL (no secret exposure, no auth bypass for unauthenticated users), but the branch must not merge until all BLOCKING items are resolved.

---

## Reviewer Verdicts

| Agent | Verdict | Blocking findings |
|---|---|---|
| security-reviewer | CHANGES REQUESTED | 2 HIGH |
| qa-engineer | CHANGES REQUESTED | 3 BLOCKING |
| architect | CHANGES REQUESTED | 2 BLOCKING |

---

## Blocking Findings (must fix before merge)

### [SECURITY HIGH] No role guard on the 4 new beneficiary routes
**File:** `lib/app/router.dart` lines 168–193

The GoRouter redirect only checks `isAuthenticated`. Any authenticated donor or driver can navigate to `/beneficiary/account`, `/beneficiary/account/personal`, `/beneficiary/account/org`, `/beneficiary/account/orders`. The personal-info form would call `updateUser` with that session's uid, allowing a donor to overwrite their own user record through the beneficiary flow.

**Fix:** Add a role check in the redirect (or a per-route guard widget) that asserts `appUser.role == UserRole.beneficiary` and redirects non-beneficiaries to `/role-router`.

---

### [SECURITY HIGH] No tests covering PII-writing update paths
**Files:** `update_personal_info_usecase.dart`, `update_org_profile_usecase.dart`, `beneficiary_account_remote_datasource.dart`

`updatePersonalInfo` writes `name`, `phone`, `location`, `photoUrl` to Firestore. `updateOrgProfile` writes `contactEmail`. Neither path has a test verifying the uid argument flows from `authStateProvider`. CLAUDE.md policy requires tests for any path touching PII.

**Fix:** Add unit tests for both use cases asserting the uid is sourced from the auth state. Add a widget test asserting the personal-info screen reads uid from `authStateProvider`.

---

### [ARCHITECT BLOCKING] Live `/orders` route crashes at runtime — `OrderHistoryNotifier.build` throws `UnimplementedError`
**Files:** `beneficiary_account_provider.dart:96`, `beneficiary_account_remote_datasource.dart:104`, `beneficiary_account_repository_impl.dart:32`

`BeneficiaryOrderHistoryScreen` calls `ref.watch(orderHistoryProvider(uid))` on first build. `OrderHistoryNotifier.build` immediately throws. Any beneficiary tapping into the Orders route crashes the app.

**Fix:** Either implement `OrderHistoryNotifier.build` and `loadMore`, or remove the `/orders` route from `router.dart` and hide the entry point until the feature is ready.

---

### [ARCHITECT BLOCKING] Cross-feature domain boundary violation — `UserProfileUpdate` imported from `features/donor/domain/`
**Files:** `beneficiary_account_repository.dart:6`, `update_personal_info_usecase.dart:2`, `beneficiary_account_remote_datasource.dart:8`

The beneficiary domain imports `UserProfileUpdate` from the donor domain, creating a hard compile-time dependency and exposing donor-only fields in a beneficiary context.

**Fix:** Create `lib/features/beneficiary/domain/entities/beneficiary_personal_info_update.dart` with only the four fields the beneficiary form writes (`name`, `phone`, `location`, `photoUrl`) and replace the donor import throughout the beneficiary feature.

---

### [QA BLOCKING] Missing loading-state test for `BeneficiaryOrderHistoryScreen` uid-empty guard
**File:** `test/widget/features/beneficiary/beneficiary_order_history_screen_test.dart`

`beneficiary_order_history_screen.dart:31-36` returns `CircularProgressIndicator` when uid is empty, but no test covers this branch.

**Fix:** Add a test overriding `authStateProvider` with `Stream.empty()`, pump once, assert `find.byType(CircularProgressIndicator)`.

---

### [QA BLOCKING] OrgProfile loading-state test is vacuous
**File:** `test/widget/features/beneficiary/beneficiary_org_profile_screen_test.dart`

The test titled `'shows CircularProgressIndicator when profile is loading'` asserts only `find.byType(Scaffold)`, which always passes.

**Fix:** Either add a real loading guard to `BeneficiaryOrgProfileScreen` and assert the spinner, or rename the test to accurately describe what is verified.

---

### [QA BLOCKING / WCAG 2.2 AA SC 4.1.2] Photo upload `GestureDetector` missing `Semantics` label
**File:** `lib/features/beneficiary/presentation/screens/beneficiary_personal_information_screen.dart` ~line 240

The photo upload tap target has no semantic label. Screen readers announce it with no description.

**Fix:**
```dart
Semantics(
  label: 'Upload profile photo',
  button: true,
  child: GestureDetector(
    onTap: _uploadingPhoto ? null : _pickImage,
    ...
  ),
)
```
Add a regression test asserting `find.bySemanticsLabel('Upload profile photo')`.

---

## Warnings (non-blocking, address in this PR or next)

| # | Agent | Item | File |
|---|---|---|---|
| W1 | Security MEDIUM | `updateUser`/`updateBeneficiary` accept raw maps with no field allowlist — a future caller could pass `role` or `uid` | `firestore_service.dart:43,421` |
| W2 | Security MEDIUM | `FirebaseAuth.instance` called statically in datasource — bypasses DI, untestable | `beneficiary_account_remote_datasource.dart:38` |
| W3 | Security LOW | Email validator accepts `@.` — replace with proper regex | `beneficiary_org_profile_screen.dart:363` |
| W4 | Security LOW | No client-side upload size cap before `putData` | `storage_service.dart:35` |
| W5 | QA WARNING | `Switch` missing `semanticLabel: 'Push notifications'` | `beneficiary_account_screen.dart:248` |
| W6 | QA WARNING | All `pumpAndSettle()` calls in new tests lack explicit `Duration` — flaky in slow CI | 4 test files |
| W7 | Architect WARNING | `StreamController()` is single-subscription — a second `listen()` throws `StateError`. Use `StreamController.broadcast()` | `beneficiary_account_remote_datasource.dart:49` |

---

## What Passed

| Check | Result |
|---|---|
| `flutter analyze` | No issues found ✓ |
| Widget test files exist for all 4 screens | ✓ |
| Empty state `'No deliveries yet'` tested | ✓ |
| Form validation `'Name is required'` tested | ✓ |
| Navigation tap to `/beneficiary/account/personal` tested | ✓ |
| `'Delivered'` and `'In Transit'` badges both tested | ✓ |
| Load More shown/hidden by `hasMore` tested | ✓ |
| No raw `Color()` or raw spacing doubles in test files | ✓ |
| No unbounded `ListView` — `SliverList` + `SliverChildBuilderDelegate` | ✓ |
| All remote images through `CachedNetworkImage` | ✓ |
| All domain entities are pure Dart — zero Flutter/Firebase imports | ✓ |
| Repository interface abstract; impl correctly implements it | ✓ |
| All new files use package-absolute imports | ✓ |
| No hardcoded secrets or credentials | ✓ |
| `photoUrl` write path coherent end-to-end | ✓ |

---

## Individual Agent Reports

- Security: `docs/agent-runs/2026-06-04-security-beneficiary-account-profile.md`
- QA: `docs/agent-runs/2026-06-04-qa-beneficiary-account-profile.md`
- Architect: `docs/agent-runs/2026-06-04-architect-beneficiary-account-profile.md`
- ADR added by architect: `docs/decisions/0012-cross-feature-domain-entity-ownership.md`
