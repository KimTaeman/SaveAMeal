# Architecture Review — feat/beneficiary-profile
Date: 2026-06-04
Reviewer: architect

## Verdict: CHANGES REQUESTED

Four issues must be resolved before merge. Two are blocking (one crashes at runtime, one is a cross-feature domain boundary violation). Two are warnings that carry forward tech-debt if left unaddressed.

---

## Findings

### [BLOCKING] `OrderHistoryEntryModel.toDomain()` throws `UnimplementedError` — order history screen will crash at runtime

**File:** `lib/features/beneficiary/data/models/order_history_entry_model.dart:26`

`OrderHistoryEntryModel.toDomain()` is declared as `throw UnimplementedError()`. The order history screen (`beneficiary_order_history_screen.dart`) watches `orderHistoryProvider(uid)`, whose notifier `build()` is also `throw UnimplementedError()` (provider file line 96). Any beneficiary who navigates to `/beneficiary/account/orders` will get an unhandled exception immediately on screen open. The `mealsReceived` field in `BeneficiaryProfile` also stays permanently `0` because no path computes it from real order data — the datasource hardcodes `mealsReceived: 0` (datasource line 44). This is not a stub, it is a production code path behind a real navigation route.

**Fix:** Either (a) implement `toDomain()` with the `status` string → `OrderHistoryEntryStatus` mapping and implement `OrderHistoryNotifier.build` and `loadMore`, or (b) remove the route `/beneficiary/account/orders` from `router.dart` and hide the "Load More" UI behind a feature flag until order history is ready. Option (b) is the minimum change that stops a runtime crash without shipping incomplete logic. The `mealsReceived: 0` hardcode is acceptable as a placeholder only if there is no live path that calls `watchOrderHistory`.

---

### [BLOCKING] `UserProfileUpdate` is imported from `donor` domain into `beneficiary` domain — cross-feature domain boundary violation

**Files:**
- `lib/features/beneficiary/domain/repositories/beneficiary_account_repository.dart:6`
- `lib/features/beneficiary/domain/usecases/update_personal_info_usecase.dart:2`
- `lib/features/beneficiary/data/datasources/beneficiary_account_remote_datasource.dart:8`
- `lib/features/beneficiary/presentation/screens/beneficiary_personal_information_screen.dart:12`

`UserProfileUpdate` lives at `lib/features/donor/domain/entities/user_profile_update.dart`. The beneficiary feature's domain repository interface and use case both import it from the donor domain. This violates the feature isolation principle: the beneficiary domain now has a compile-time dependency on the donor domain. Any rename, refactor, or removal of `UserProfileUpdate` in the donor feature will silently break the beneficiary domain. The entity itself carries donor-specific fields (`orgName`, `managerName`, `bannerUrl`, `surplusTypes`, `operatingHours`) that are irrelevant and confusing in a beneficiary personal info update.

**Fix:** Move `UserProfileUpdate` to `lib/shared/` (e.g., `lib/shared/domain/user_profile_update.dart`) so both features can import from a neutral location, or create a separate `BeneficiaryPersonalInfoUpdate` entity in `lib/features/beneficiary/domain/entities/` with only the fields the beneficiary screen actually writes (`name`, `phone`, `location`, `photoUrl`). The second option is strongly preferred: it keeps the donor and beneficiary update shapes decoupled and prevents the beneficiary form from ever accidentally sending donor-only fields.

---

### [WARNING] `FirebaseAuth.instance` accessed directly inside the datasource — bypasses DI, untestable

**File:** `lib/features/beneficiary/data/datasources/beneficiary_account_remote_datasource.dart:38`

`FirebaseAuth.instance.currentUser?.metadata.creationTime` is called directly inside `BeneficiaryAccountRemoteDatasourceImpl.watchProfile`. This is a static service locator call, not dependency injection. Consequences: (1) the datasource cannot be unit-tested without a live Firebase project or `firebase_auth_mocks`; (2) if the team ever moves auth to a different provider, this call must be hunted down rather than swapped at the DI layer.

**Fix:** Either inject `FirebaseAuth` into the datasource constructor alongside `FirestoreService`, or pass `joinedAt` in from the presentation layer (it can be read via `authStateProvider` which already wraps `FirebaseAuth`). The constructor-injection approach is preferred: it makes the datasource fully mockable and consistent with how `FirebaseFirestore` is injected into `FirestoreService`.

---

### [WARNING] `watchProfile` `StreamController` is not broadcast — second `listen()` call will throw

**File:** `lib/features/beneficiary/data/datasources/beneficiary_account_remote_datasource.dart:49–70`

`StreamController<BeneficiaryProfileModel?>()` creates a single-subscription stream. The `currentBeneficiaryProfile` stream provider and any other provider that calls `watchProfile` from the same datasource instance will each attempt to subscribe. The second `listen()` on a single-subscription stream throws a `StateError` at runtime. The existing donor `watchVolunteerQueue` pattern in `FirestoreService` has the same structure but is only ever subscribed once at a time (through a single provider). The beneficiary profile stream is watched by both `currentBeneficiaryProfileProvider` and directly from presentation screens via `ref.listen`, so multiple listeners are plausible.

**Fix:** Use `StreamController<BeneficiaryProfileModel?>.broadcast()`. This matches the pattern used for the equivalent merge-stream in `FirestoreService.watchVolunteerQueue`. No subscription-leak risk is introduced by the broadcast mode because `onCancel` cancels both upstream subscriptions when the last listener unsubscribes.

---

## Summary

| # | Severity | File | Issue |
|---|----------|------|-------|
| 1 | BLOCKING | `order_history_entry_model.dart:26`, `beneficiary_account_provider.dart:96-98`, `router.dart:186` | `toDomain()` and `OrderHistoryNotifier.build/loadMore` are `UnimplementedError` behind a live route |
| 2 | BLOCKING | `beneficiary_account_repository.dart:6`, `update_personal_info_usecase.dart:2` | `UserProfileUpdate` from `donor` domain imported into `beneficiary` domain |
| 3 | WARNING | `beneficiary_account_remote_datasource.dart:38` | `FirebaseAuth.instance` static access — untestable, bypasses DI |
| 4 | WARNING | `beneficiary_account_remote_datasource.dart:49` | Single-subscription `StreamController` — second `listen()` will throw |

**What is clean:** Domain entities (`BeneficiaryProfile`, `BeneficiaryOrgProfileUpdate`, `OrderHistoryEntry`) are pure Dart with zero Flutter or Firebase imports. The repository interface is abstract and lives in the domain layer. `BeneficiaryProfileModel.toDomain()` is correctly implemented (the only `toDomain()` that works). All imports use package-absolute paths — no relative imports found. `CachedNetworkImage` is used for all remote photo rendering. `ListView` is not used; `SliverList` / `SliverChildBuilderDelegate` are used correctly. The DI chain in `beneficiary_account_provider.dart` wires datasource → repository → use cases in the correct order. `FirestoreService.watchUser` and `watchBeneficiaryDoc` are both proper single-subscription Firestore snapshot streams; the merge `StreamController` cancels both upstreams on cancel — no subscription leak for the current single-listener usage.

**Minimum to unblock merge:** Resolve findings 1 and 2. Finding 3 and 4 should be addressed in this PR but are not release-blockers if the team accepts the test coverage gap for now.
