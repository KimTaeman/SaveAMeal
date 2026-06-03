# PR Review — feature/donor-account-screens

**Date:** 2026-06-03
**Reviewer:** Architect agent
**Author:** chotiya (flutter-engineer)
**Verdict:** CHANGES REQUESTED

---

## Overall Verdict

**CHANGES REQUESTED** — Two high-severity issues must be resolved before merge. The domain layer leaks Firestore field-key knowledge through the untyped `Map<String, dynamic>` API, and `UserModel` (a Freezed + JSON-serializable class) is used directly as a domain interface type, blurring the boundary between the data and domain layers. One additional hardcoded-color violation also needs fixing. Everything else is either acceptable given the project's current stage or matches established patterns.

---

## Findings

| # | Severity | Layer | Description | Required fix |
|---|----------|-------|-------------|--------------|
| 1 | **High** | Domain | `DonorAccountRepository` and `UpdateUserUsecase` take `Map<String, dynamic> fields`. This is an untyped, stringly-keyed API — callers in `PersonalInformationScreen` and `OrganizationProfileScreen` pass raw Firestore field names (`'name'`, `'phone'`, `'operatingHours'`, `'bannerUrl'`, etc.) directly through the domain boundary. This leaks Firestore schema knowledge into the presentation layer and makes the domain API unsearchable, unvalidatable, and impossible to refactor safely. The domain layer should express intent, not wire format. | Replace `Map<String, dynamic>` with a typed value object. Create `domain/entities/user_profile_update.dart` — a plain Dart class (no Freezed required) with named optional fields for every updatable attribute. The use case accepts `UserProfileUpdate`; the repository impl maps it to a `Map<String, dynamic>` before passing to Firestore. |
| 2 | **High** | Domain | `DonorAccountRepository.getUser()` returns `UserModel?`, where `UserModel` is `@freezed` with `fromJson`/`toJson`. Importing `core/models/user_model.dart` into the domain layer does not pull in Flutter or Firebase directly, but `UserModel` is coupled to JSON serialization and code-generation machinery (`freezed_annotation`, `json_serializable`). The established pattern in this codebase is for domain entities to be plain Dart classes (see `AppUser`, `Batch`, `BatchItem`, `DonorMetrics`, `Beneficiary`), while Freezed models live in `data/models/`. By surfacing `UserModel` in the domain interface the team loses the ability to change serialization format or JSON keys without touching the domain layer. | Introduce a `domain/entities/donor_profile.dart` plain Dart entity containing the fields the domain cares about (matching the current `UserModel` fields minus the codegen annotations). The domain repository interface returns `DonorProfile?`. `DonorAccountRepositoryImpl` maps `UserModel` → `DonorProfile`. `UserModel` stays in `data/`. This is consistent with every other feature entity in the codebase. |
| 3 | **Medium** | Presentation | `donor_account_provider.dart` imports `DonorAccountRemoteDatasourceImpl` and `DonorAccountRepositoryImpl` (both concrete data-layer classes) directly. The existing `donor_provider.dart` does the same (imports `DonorRemoteDatasourceImpl` and `DonorRepositoryImpl`), so this PR is internally consistent with the established pattern. However the pattern itself means the presentation layer is coupled to concrete implementations; swapping the datasource (e.g. from Firestore to REST) requires touching provider files. This is a known architectural compromise acceptable at the current project stage — it matches the existing codebase pattern exactly and does not introduce new debt. | Advisory only. If/when the team decides to invert this, move all concrete wiring to a DI registration file in `core/` and have providers depend only on the abstract interfaces. No action required for this PR. |
| 4 | **Medium** | Presentation | `DonorAccountScreen` calls `FirebaseAuth.instance.currentUser?.metadata.creationTime` directly (line 31). This is a Firebase SDK call in a screen widget, bypassing the repository and domain layers entirely. It is not a `FirestoreService` call, but it is still a backend-framework import in the presentation layer and creates a second pathway for auth data outside the established `authStateProvider` pattern. | Surface `creationTime` through the domain. Extend `AppUser` with a nullable `DateTime? createdAt` field, populate it in `AuthRemoteDatasource` from `firebaseUser.metadata.creationTime`, and read it via `authStateProvider` in the screen. Remove the `import 'package:firebase_auth/firebase_auth.dart'` from `donor_account_screen.dart`. |
| 5 | **Low** | Presentation | Multiple hardcoded `Color(0xFF006E2F)` literals appear across all three new screens (`donor_account_screen.dart` lines 64, 135, 138; `personal_information_screen.dart` lines 78, 166, 169, 283; `organization_profile_screen.dart` lines 21, 310, 405, etc.) and in private widget subclasses (`_StatChip`, `_SurplusTypesCard`). The convention states no hardcoded colors — always use `cs.*` or `ac.*`. | Replace all hardcoded `Color(0xFF006E2F)` with `cs.primary` or the appropriate `ac.*` token. Run `flutter analyze` to confirm no remaining hardcoded color literals. |
| 6 | **Low** | Domain | `UserModel.operatingHours` is typed as `List<Map<String, String>>`. `json_serializable` does support this type natively without a custom converter — the generated code will emit `List<Map<String, String>>`. However, if any Firestore document stores a `null` value for an individual entry key, deserialization will throw at runtime because the generated code casts map values as non-nullable `String`. This is a latent data-integrity risk rather than a current code defect. | Advisory. If `operatingHours` is migrated to a typed entity (as recommended in finding #2), this is resolved naturally. In the interim, consider adding defensive null-coalescing in `FirestoreService._normalise`. No merge blocker. |
| 7 | **Low** | Data | `FirestoreService.updateUser` uses `.update()` while `createUser` uses `.set()`. Calling `.update()` on a document that does not exist will throw `firebase_core` `PlatformException` with "NOT_FOUND". If a user document was never created (e.g. sign-up failed midway), a subsequent profile save will throw a confusing error with no fallback. | Change `updateUser` to use `.set(fields, SetOptions(merge: true))`. This is idempotent, handles missing documents, and matches the semantics the callers intend. |
| 8 | **Pass** | Presentation | `currentUserProvider` watches `authStateProvider` and then calls `donorAccountRepositoryProvider.getUser()`. `authStateProvider` is a `Stream<AppUser?>` provider from auth. There is no dependency cycle: auth → account is one-directional and matches the existing `donorMetrics(uid)` provider pattern. No concern. | No action required. |
| 9 | **Pass** | Presentation | No screen imports `FirestoreService` directly. All three screens depend only on presentation providers (`donor_account_provider.dart`, `auth_provider.dart`, `donor_provider.dart`) and `service_providers.dart` (for `storageServiceProvider` and `locationServiceProvider`). The repository layer bypass check passes. | No action required. |

---

## Pattern Consistency Assessment

The wiring pattern in `donor_account_provider.dart` (datasource provider → repository provider → use case provider) is **identical** to `donor_provider.dart` and `auth_provider.dart`. The PR is internally consistent with the established codebase pattern on this axis.

Domain use case structure matches `CreateBatchUsecase`, `GetDonorMetricsUsecase`, and `WatchActiveBatchesUsecase` — single-responsibility, constructor injection, delegates to repository. The `UpdateUserUsecase` is consistent.

The divergence from pattern is specifically: existing donor entities (`Batch`, `BatchItem`, `DonorMetrics`, `Beneficiary`) are pure Dart plain classes with zero codegen annotations. `UserModel` is the only Freezed-annotated type that surfaces in a domain interface. This inconsistency is the root of finding #2.

---

## Tradeoffs

- **Typed `UserProfileUpdate` entity (finding #1):** Upside — domain API is self-documenting, compile-safe, and backend-agnostic. Downside — requires a new file and mapper in the repository impl; slightly more boilerplate per field added in future. Reversal cost is low — it is a pure addition with a clear migration path.

- **Separate `DonorProfile` domain entity vs. reusing `UserModel` (finding #2):** Upside — preserves domain purity, consistent with all other feature entities; the data layer can change serialization without touching domain. Downside — mapper code to maintain; two types to keep in sync. Reversal cost is medium — callers in presentation that currently reference `UserModel` fields would need updating.

- **`.set(merge: true)` vs `.update()` (finding #7):** Upside — eliminates NOT_FOUND throws, idempotent, no additional reads. Downside — if a caller accidentally omits a field, it will not be detected (no partial-update enforcement). Given callers always pass explicit field maps this is acceptable.

---

## Sign-off

This PR is **NOT approved for merge** in its current state. Findings #1, #2, and #4 must be resolved. Finding #7 is strongly recommended before merge. Findings #3, #5, #6 are advisory and may be tracked as follow-up issues.

Reviewed by: Architect agent
Date: 2026-06-03
