# Architect Re-Review — donor-account-screens (v2)

**Date:** 2026-06-03
**Reviewer:** Architect agent
**Branch:** feature/donor-account-screens
**Previous review:** docs/agent-runs/2026-06-03-architect-donor-account-screens.md (CHANGES REQUESTED)
**Purpose:** Verify that every blocking finding from v1 is resolved before merge approval.

---

## Overall Verdict

**CHANGES REQUESTED**

One HIGH finding (UserModel in domain return type) remains open. The ADR-0008 decision explicitly requires a plain Dart `DonorProfile` entity — the ADR was accepted but the implementation does not yet comply. All other blocking findings are resolved. The hardcoded-color advisory is still present and must be resolved before the next release cycle.

---

## Finding Resolution Table

| Finding | Previous Status | Current Status | Action Required |
|---|---|---|---|
| HIGH: Untyped `Map<String,dynamic>` in domain interface | BLOCKING | RESOLVED | None |
| HIGH: `UserModel` (Freezed+JSON) in domain return type | BLOCKING | STILL OPEN | Introduce `DonorProfile` domain entity; map in repository impl |
| HIGH: `firebase_auth` imported in `DonorAccountScreen` | BLOCKING | RESOLVED | None |
| STRONGLY RECOMMENDED: `.update()` → `.set(merge:true)` | ADVISORY | RESOLVED | None |
| LOW: Hardcoded `Color(0xFF006E2F)` in screens | ADVISORY | STILL PRESENT | Promote to `AppColors` before next release |
| NEW: `toMap()` on domain entity | — | ADVISORY | Move to data layer extension |
| NEW: Provider imports concrete data types | — | ADVISORY | Track in backlog; acceptable for now |

---

## Detailed Findings

### 1. HIGH (STILL OPEN) — `UserModel` in domain return type

**File:** `apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart`, line 7

```dart
Future<UserModel?> getUser(String uid);
```

`UserModel` is a `@freezed` class annotated with `freezed_annotation` and `json_serializable` (confirmed in `apps/mobile/lib/core/models/user_model.dart`). ADR-0008 was written, accepted, and explicitly chose Option 2: introduce a plain Dart `DonorProfile` domain entity and keep `UserModel` in `data/`. The ADR is accepted but not implemented. The domain repository interface, the use-case file, `donor_account_provider.dart`, and `DonorAccountScreen` all still reference `UserModel` directly in their return types and watch expressions.

This is a policy violation against the project's own stated constraint ("Domain layer: zero Flutter or backend imports — pure Dart only") and against ADR-0008 which was raised specifically because of this PR.

**Required fix:** Create `apps/mobile/lib/features/donor/domain/entities/donor_profile.dart` as a plain Dart class. Change `DonorAccountRepository.getUser()` to return `DonorProfile?`. Add a mapper in `DonorAccountRepositoryImpl` that converts `UserModel` to `DonorProfile`. Update `donor_account_provider.dart` and `DonorAccountScreen` to consume `DonorProfile` instead of `UserModel`.

---

### 2. RESOLVED — Untyped `Map<String,dynamic>` in domain interface

`UserProfileUpdate` typed entity exists at `apps/mobile/lib/features/donor/domain/entities/user_profile_update.dart` with zero Flutter or backend imports. The domain interface and use case both accept `UserProfileUpdate`. `toMap()` is called only in `DonorAccountRemoteDatasourceImpl` at the data-layer boundary. The `Map<String,dynamic>` is fully contained to the data layer. Finding is closed.

---

### 3. RESOLVED — `firebase_auth` import in `DonorAccountScreen`

`apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart` has no `firebase_auth` import. The `_memberSince()` method and "Member since" text are gone. The screen obtains the uid via `authStateProvider` only. Finding is closed.

---

### 4. RESOLVED — `.update()` replaced with `.set(merge: true)`

`apps/mobile/lib/services/firestore_service.dart` line 43-46:

```dart
Future<void> updateUser(String uid, Map<String, dynamic> fields) => _db
    .collection(FirestoreConstants.users)
    .doc(uid)
    .set(fields, SetOptions(merge: true));
```

Correct. Partial-update semantics are preserved; missing-document risk is eliminated. Finding is closed.

---

### 5. ADVISORY (STILL PRESENT) — Hardcoded `Color(0xFF006E2F)` and `Color(0xFFEAF0E5)`

`DonorAccountScreen` and the private `_StatChip` widget both contain hardcoded color literals. Affected lines in `donor_account_screen.dart`: 52, 57, 92, 124, 130, 270, 274, 278, 283. The convention documented in `CLAUDE.md` states "No hardcoded colors — always use `cs.*` or `ac.*`". This was advisory in v1 and remains so here, but it must be resolved before the feature is considered production-ready. Suggest adding `brandGreen`, `brandGreenLight`, `badgeGold`, and `badgeGoldText` tokens to `AppColors`.

---

### 6. ADVISORY — `toMap()` placement on domain entity

`UserProfileUpdate.toMap()` returns `Map<String, dynamic>` and its key names (`'name'`, `'orgName'`, `'photoUrl'`, etc.) mirror Firestore document field names exactly. This makes the domain entity implicitly aware of the storage schema. The method is currently the only consumer of this knowledge, called exclusively from `DonorAccountRemoteDatasourceImpl`.

Recommended path: remove `toMap()` from `UserProfileUpdate` and add a private extension or static factory method inside `DonorAccountRemoteDatasourceImpl` (or a dedicated mapper class in `data/`). This is non-blocking for this PR but should be addressed alongside the `DonorProfile` work in finding 1, since both require touching the same files.

---

### 7. ADVISORY — Provider wires concrete data types directly

`donor_account_provider.dart` imports `DonorAccountRemoteDatasourceImpl` and `DonorAccountRepositoryImpl` by concrete class name. This is consistent with `donor_provider.dart` and is the established project pattern for Riverpod wiring. It is not a violation of the domain boundary (the providers live in `presentation/`) but it does mean swapping the data implementation requires editing the provider file. Acceptable as advisory; track in backlog alongside a future dependency-injection improvement shared across all features.

---

## Summary of Actions Required Before Merge

| Priority | Action | Owner |
|---|---|---|
| BLOCKING | Create `DonorProfile` plain Dart entity; update repository interface, impl mapper, provider, and screen | Flutter Engineer |
| BLOCKING | Remove `toMap()` from `UserProfileUpdate`; move serialisation logic to data layer | Flutter Engineer (can be done in same PR as above) |
| ADVISORY (post-merge) | Promote `Color(0xFF006E2F)`, `Color(0xFFEAF0E5)`, `Color(0xFFD7A400)`, `Color(0xFF523D00)` to `AppColors` tokens | Flutter Engineer |
| ADVISORY (backlog) | Refactor all feature providers to depend on interfaces rather than concrete implementations | Architect to spec; Flutter Engineer to implement |

---

## Sign-off

Re-review conducted by Architect agent on 2026-06-03. Three of five original findings are resolved. The remaining HIGH finding (UserModel in domain interface) directly contradicts ADR-0008 which was written in response to this same PR. The branch may not merge until finding 1 is implemented. A third review pass is required after the `DonorProfile` entity is introduced.
