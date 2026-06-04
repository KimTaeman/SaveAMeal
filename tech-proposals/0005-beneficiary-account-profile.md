---
title: "0005: Beneficiary Account & Profile"
description: "Add a fully functional Account tab to the beneficiary shell so beneficiaries can view and edit personal information, manage their organisation profile, review delivery history, and control notification preferences."
---

# PROP-0005: Beneficiary Account & Profile

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-03
**Spec:** (pending approval)
**Approved by:** architect

---

## Problem

The `BeneficiaryHomeScreen` bottom `NavigationBar` declares four destinations — Home (index 0), Track (index 1), Impact (index 2), and Account (index 3) — but `router.dart` registers only one named sub-route under `/beneficiary` (`delivery/:batchId` and `tracking`). Tapping index 3 invokes `context.go('/beneficiary/account')`, which has no matching `GoRoute`, causing a silent navigation failure: the shell stays on the current screen with no feedback to the user.

Beyond fixing a broken tap target, no account surface exists for beneficiaries at all. They cannot:

- View or edit personal information (name, phone, photo, location) stored in `users/{uid}`.
- View or edit their organisation profile (name, address, lat/lng, and the three proposed additive fields) stored in `beneficiaries/{uid}`.
- Browse their delivery history (completed `batches` documents where `beneficiaryId == uid` and `status in [delivered, closed]`).
- Toggle push notification preferences.
- Log out from within the beneficiary shell.

This is a P1 gap because the broken tab is visible to every beneficiary on every launch.

---

## Goals

- Wire GoRouter to resolve `/beneficiary/account`, `/beneficiary/account/personal`, and `/beneficiary/account/org` so tapping index 3 navigates correctly.
- Deliver a `BeneficiaryAccountScreen` at `/beneficiary/account` that mirrors the structure of `DonorAccountScreen` — profile card with photo and role badge, stat chips, Account Settings list (notifications toggle, personal info, org profile), and log-out button.
- Deliver a `BeneficiaryPersonalInformationScreen` at `/beneficiary/account/personal` that reads and writes the `users/{uid}` document (fields: `name`, `email`, `phone`, `photoUrl`, `location`) via the existing `FirestoreService.updateUser` / `FirestoreService.getUser` path, reusing the `UpdateUserUsecase`-style pattern from the donor side.
- Deliver a `BeneficiaryOrgProfileScreen` at `/beneficiary/account/org` that reads and writes `beneficiaries/{uid}`, extending the existing `BeneficiaryModel` (id, name, address, lat, lng) with three additive fields: `orgType` (`String?`), `contactEmail` (`String?`), and `missionStatement` (`String?`).
- Expose a `BeneficiaryAccountRepository` (domain interface) and `BeneficiaryAccountRepositoryImpl` (data implementation) that provides `getProfile`, `updatePersonalInfo`, and `updateOrgProfile` methods, keeping the domain layer free of Firestore or Flutter imports.
- Add a `beneficiaryAccountProvider.dart` in `presentation/providers/` that wires datasource → repository → use cases, following the same shape as `donor_account_provider.dart`.
- Add a `DeliveryHistoryScreen` (or an inline section on the account screen) backed by a Firestore query `batches` where `beneficiaryId == uid && status in [delivered, closed]`, using a `StreamProvider` for live updates.
- Every new screen must have a widget test under `apps/mobile/test/widget/`.

---

## Non-goals

- Creating any new Firestore collection — all reads/writes target existing `users/{uid}` and `beneficiaries/{uid}` paths already covered by `firestore.rules`.
- Modifying `firestore.rules` — the existing rules already allow a beneficiary to read/write their own `users/{uid}` and `beneficiaries/{uid}` documents.
- Push notification delivery (FCM) — the toggle persists a preference flag; actual push dispatch is a separate feature.
- An impact/analytics tab — index 2 ("Impact") is out of scope for this proposal.
- Introducing any new third-party package.
- Photo upload for the org profile banner (the personal photo upload path via `StorageService.uploadProfilePhoto` is reusable; the banner path is a stretch goal).

---

## Options

### Option A — Mirror the donor account pattern, all files inside `features/beneficiary/` *(Recommended)*

**Description.**

Replicate the donor account layer stack verbatim, substituting beneficiary-specific types and Firestore paths:

| Donor file | Beneficiary equivalent |
|---|---|
| `donor/domain/entities/donor_profile.dart` | `beneficiary/domain/entities/beneficiary_profile.dart` |
| `donor/domain/entities/user_profile_update.dart` | Reuse as-is — `UserProfileUpdate` is already role-agnostic |
| `donor/domain/repositories/donor_account_repository.dart` | `beneficiary/domain/repositories/beneficiary_account_repository.dart` |
| `donor/domain/usecases/update_user_usecase.dart` | `beneficiary/domain/usecases/update_beneficiary_user_usecase.dart` |
| `donor/data/datasources/donor_account_remote_datasource.dart` | `beneficiary/data/datasources/beneficiary_account_remote_datasource.dart` |
| `donor/data/repositories/donor_account_repository_impl.dart` | `beneficiary/data/repositories/beneficiary_account_repository_impl.dart` |
| `donor/presentation/providers/donor_account_provider.dart` | `beneficiary/presentation/providers/beneficiary_account_provider.dart` |
| `donor/presentation/screens/donor_account_screen.dart` | `beneficiary/presentation/screens/beneficiary_account_screen.dart` |
| `donor/presentation/screens/personal_information_screen.dart` | Reuse — the screen is already role-agnostic in its data path |
| `donor/presentation/screens/organization_profile_screen.dart` | `beneficiary/presentation/screens/beneficiary_org_profile_screen.dart` |

The `BeneficiaryAccountRepository` interface adds two new methods beyond the donor equivalent:

```
abstract class BeneficiaryAccountRepository {
  Future<BeneficiaryProfile?> getProfile(String uid);
  Future<void> updatePersonalInfo(String uid, UserProfileUpdate update);
  Future<void> updateOrgProfile(String uid, BeneficiaryOrgProfileUpdate update);
}
```

`BeneficiaryOrgProfileUpdate` is a new pure-Dart value object (analogous to `UserProfileUpdate`) carrying the three additive `beneficiaries/{uid}` fields: `orgType`, `contactEmail`, `missionStatement`, plus the existing `name`, `address`.

The `BeneficiaryProfile` domain entity holds the union of `users/{uid}` and `beneficiaries/{uid}` data needed by the UI:

```
class BeneficiaryProfile {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? location;
  final String? photoUrl;
  final String? orgName;      // from beneficiaries/{uid}.name
  final String? address;
  final String? orgType;
  final String? contactEmail;
  final String? missionStatement;
}
```

`BeneficiaryAccountRemoteDatasource` calls `FirestoreService.getUser(uid)` for the `users` path and `FirestoreService.getBeneficiary(uid)` (to be added to `FirestoreService`) for the `beneficiaries` path. For the org profile write, it calls `FirestoreService.updateBeneficiary(uid, map)` (also to be added). The existing `FirestoreService.updateUser` / `FirestoreService.getUser` covers the personal info path without change.

The `beneficiary_account_provider.dart` wires DI identically to `donor_account_provider.dart`, registering `@riverpod` providers for datasource, repository, and use cases. A `currentBeneficiaryUserProvider` mirrors `currentUserProvider`.

Delivery history is a `StreamProvider` backed by a `batches` Firestore query with two filters: `beneficiaryId == uid` and `status in ['delivered', 'closed']`. Because `batches` is already in scope (all signed-in users can read per `firestore.rules`), no rules change is needed. This provider lives in `beneficiary_account_provider.dart` or a dedicated `beneficiary_history_provider.dart`.

GoRouter changes: add three new `GoRoute` entries nested under `/beneficiary` — `account`, `account/personal`, and `account/org` — and update the `NavigationBar` `onDestinationSelected` handler for index 3 to call `context.go('/beneficiary/account')`.

**Pros:**

- Zero new patterns to learn — the data flow, provider shape, and screen structure are identical to the already-reviewed donor account feature.
- All files stay inside `features/beneficiary/`, preserving Clean Architecture feature isolation.
- The `UserProfileUpdate` value object is reused without modification for the personal info path, keeping the Domain layer DRY.
- `BeneficiaryRepository` (currently a stub with a `// TODO`) can absorb `getBeneficiary` / `updateBeneficiary` contract methods, paying down existing technical debt.
- No new Firestore collections, no new third-party packages, no rules changes.

**Cons:**

- `FirestoreService` gains two new methods (`getBeneficiary`, `updateBeneficiary`) — minor service expansion.
- The `BeneficiaryAccountRepository` reads from two Firestore documents per profile load (`users/{uid}` + `beneficiaries/{uid}`), resulting in two reads instead of one. This is acceptable for an account screen (infrequently opened) but is a latency cost to acknowledge.
- Delivery history adds a Firestore query with a compound filter on `batches`; Firestore requires a composite index for `(beneficiaryId, status)`. The index must be created in the Firebase console or via `firestore.indexes.json` before the query works in production.

**Effort:** Small–medium. ~12 new files (entity, value object, repo interface, repo impl, datasource, provider, 3 screens, plus widget tests for each screen). No schema changes beyond additive fields on `beneficiaries/{uid}`.

---

### Option B — Shared generic account module under `lib/shared/` or `lib/features/account/`

**Description.**

Extract a single generic account feature module that both donor and beneficiary shells consume. A `GenericAccountScreen` accepts a configuration object (profile data, menu items, stats) and renders accordingly. Shared providers read from `users/{uid}` for personal info; role-specific org profile screens are injected as callbacks or sub-routes.

**Pros:**

- Eliminates duplication if more roles (e.g. a future "volunteer account" tab) are added later.
- A single `AccountRepository` abstraction for `users/{uid}` reads/writes.

**Cons:**

- The donor org profile (supermarket name, manager, operating hours, surplus types) and the beneficiary org profile (org type, mission statement, contact email) are structurally different enough that a shared screen quickly becomes a conditional-heavy widget tree — precisely the kind of coupling Clean Architecture discourages.
- Routing becomes more complex: a shared screen must know which sub-routes to expose per role, pushing role logic into `shared/`, which should be role-agnostic.
- Higher up-front design cost for a generic abstraction that currently serves only two roles and may never serve more.
- Harder to review: a single PR touches both the donor and beneficiary shells, making the change surface larger than necessary.

**Effort:** Medium–large. Requires designing and agreeing on the shared abstraction before any screen can be written.

**Verdict:** Rejected for this proposal. The structural divergence between donor and beneficiary org profiles makes a generic screen fragile. Option A's duplication is small and well-bounded; if a third role requires an account tab, the abstraction can be extracted at that point with two concrete examples as guidance.

---

### Option C — Lift personal info into a shared `users/` feature; keep org profile role-specific

**Description.**

Split the concern: create `lib/features/users/` for all `users/{uid}` CRUD (shared across roles), and keep `beneficiary/` for the org profile. `PersonalInformationScreen` is moved to `features/users/` and routed from both `/donor/account/personal` and `/beneficiary/account/personal`.

**Pros:**

- `users/{uid}` logic is written once; any role can reuse it without duplication.
- The domain entity for personal info (`UserProfile`) lives in a neutral module.

**Cons:**

- Moving the existing `PersonalInformationScreen` from `features/donor/` to `features/users/` changes a working donor screen, introducing regression risk outside this PR's scope.
- The router currently imports the screen from the donor path; changing the import requires touching `router.dart` for a non-beneficiary concern.
- This refactor is a separate architectural decision (see ADR-0008 on domain entity vs shared model) and should not be bundled with a P1 bug fix.

**Effort:** Medium. Requires a cross-feature refactor and a donor-side regression test pass.

**Verdict:** Rejected for this proposal. The concern is valid and worth revisiting as a standalone refactor (tech proposal 0006 or an ADR amendment), but bundling it with the P1 account-tab fix delays delivery unnecessarily. Option A's `UpdateUserUsecase` reuse (via `beneficiary/domain/usecases/`) already avoids duplicating business logic.

---

## Recommendation

**Recommended: Option A — Mirror the donor pattern, all files inside `features/beneficiary/`.**

Option A directly resolves the P1 broken tab with the smallest change surface: it introduces no new abstractions, reuses the already-reviewed `UpdateUserUsecase`/`UserProfileUpdate`/`FirestoreService` path, and keeps every new file inside `features/beneficiary/` where reviewers can audit it in isolation. The two-document read cost per profile load is negligible for an account screen; the composite index requirement for delivery history is a known, documented Firestore deployment step. If a third role with an account tab is added in future, extracting a shared module at that point will have two concrete templates (donor + beneficiary) rather than speculating on the abstraction now.

---

## Open Questions

1. **`PersonalInformationScreen` reuse vs. mirror.** The existing `PersonalInformationScreen` imports `donor_account_provider.dart` directly (e.g. `ref.watch(currentUserProvider)`, `ref.read(updateUserUsecaseProvider)`). Should the beneficiary implementation reuse this screen by making the provider dependencies injectable, or should it be mirrored as `BeneficiaryPersonalInformationScreen` with its own `currentBeneficiaryUserProvider`? Mirroring is safer (no donor regression risk) but adds ~350 lines of near-duplicate code. Injection is cleaner but requires a provider-parameter refactor of a working screen.

2. **Composite Firestore index for delivery history.** The query `batches` where `beneficiaryId == uid && status in ['delivered', 'closed']` requires a composite index on `(beneficiaryId ASC, status ASC)`. Does a `firestore.indexes.json` file exist in this repo, or is the index managed manually in the Firebase console? The answer determines whether the engineer must add an index definition file as part of this feature.

3. **Stat chips on `BeneficiaryAccountScreen`.** The donor account card shows "Total Donations (kg)" and "Organisations Helped". What equivalent stats should appear on the beneficiary card? Candidates: "Meals Received" (count of `status == collected` intake requests) and "Deliveries This Month". Confirmation needed before the spec is written, as it determines whether a new aggregation query or `impactMetrics/{uid}` field is required.

4. **`beneficiaries/{uid}` write path.** `FirestoreService` currently exposes `updateUser` (writes to `users/{uid}`) but has no `updateBeneficiary` method. Should this method be added to the existing `FirestoreService` class, or should a separate `BeneficiaryFirestoreService` be introduced? Adding to the existing service keeps the interface surface small; a separate service maintains stricter separation but adds a new file.

5. **Navigation index 3 guard.** The `NavigationBar` in `BeneficiaryHomeScreen` currently handles only `case 0` in its `onDestinationSelected` switch, leaving indices 1–3 as dead code. The fix for index 3 is clear (navigate to `/beneficiary/account`), but indices 1 (Track) and 2 (Impact) also have no routes. Should this proposal fix all four cases (routing stub screens for 1 and 2) or only fix the account tab in scope?

---

## Acceptance Criteria

**Routing**

- Tapping index 3 on the beneficiary `NavigationBar` navigates to `/beneficiary/account` without error.
- `/beneficiary/account`, `/beneficiary/account/personal`, and `/beneficiary/account/org` are all registered in `router.dart`.
- The Back button on `BeneficiaryPersonalInformationScreen` and `BeneficiaryOrgProfileScreen` pops to `/beneficiary/account`.

**Domain layer**

- `BeneficiaryProfile` entity is pure Dart — zero Flutter or Firebase imports.
- `BeneficiaryOrgProfileUpdate` value object is pure Dart.
- `BeneficiaryAccountRepository` interface is pure Dart, defines `getProfile`, `updatePersonalInfo`, and `updateOrgProfile`.
- All new use cases are pure Dart with a single public `call` method.

**Data layer**

- `BeneficiaryAccountRemoteDatasourceImpl` is the only file in `features/beneficiary/` that imports `FirestoreService`.
- Personal info writes target `users/{uid}` via `FirestoreService.updateUser`.
- Org profile reads and writes target `beneficiaries/{uid}` via new `FirestoreService.getBeneficiary` / `FirestoreService.updateBeneficiary` methods.
- `BeneficiaryRepositoryImpl` (currently a stub) is extended or replaced by `BeneficiaryAccountRepositoryImpl`; the stub `// TODO` placeholders are resolved.

**Presentation layer**

- `beneficiary_account_provider.dart` wires datasource → repository → use cases using `@riverpod` code generation.
- A `currentBeneficiaryUserProvider` (`FutureProvider<BeneficiaryProfile?>`) provides profile data to all three account screens.
- Presentation providers depend only on domain interfaces — no direct import of `BeneficiaryAccountRepositoryImpl` or `BeneficiaryAccountRemoteDatasourceImpl`.
- `BeneficiaryAccountScreen` displays: profile photo (via `CachedNetworkImage` if `photoUrl` is non-null), role badge, stat chips, notification toggle, links to personal info and org profile sub-screens, and a log-out button.
- `BeneficiaryOrgProfileScreen` displays editable fields for `name`, `address`, `orgType`, `contactEmail`, and `missionStatement`. Saving writes to `beneficiaries/{uid}`.
- Delivery history (either inline section or dedicated screen) shows completed deliveries from `batches` filtered by `beneficiaryId == uid` and `status in [delivered, closed]`, rendered with `ListView.builder`.
- All colors accessed via `cs.*` or `ac.*`; all text styles via `Theme.of(context).textTheme`; all spacing via `Spacing.*`.

**Tests**

- Widget test for `BeneficiaryAccountScreen` — renders profile card, settings list, and log-out button.
- Widget test for `BeneficiaryPersonalInformationScreen` (or assertion that the reused donor screen is covered by its existing test).
- Widget test for `BeneficiaryOrgProfileScreen` — renders all five editable fields.

**No regressions**

- `DonorAccountScreen`, `PersonalInformationScreen`, and `OrganizationProfileScreen` are unmodified (unless Open Question 1 is resolved in favour of injection).
- `firestore.rules` is unmodified.
- `flutter analyze` passes with zero new warnings.
