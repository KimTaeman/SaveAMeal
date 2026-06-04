# Session: 2026-06-03 — beneficiary-account-profile

**Date:** 2026-06-03
**Member:** NichapaJongKmutt
**Agent:** flutter-engineer
**Task:** Scaffold and implement SPEC-0005 Beneficiary Account & Profile

---

## Context

SPEC-0005 is APPROVED (status: APPROVED, author: architect, date: 2026-06-03). The beneficiary shell NavigationBar index 3 currently produces a silent navigation failure because no GoRoute exists for `/beneficiary/account`. This session creates all stub files required by the spec before implementation begins.

Reference: `C:\SaveAMeal\tech-specs\0005-beneficiary-account-profile.md`

## Plan

1. [ ] `lib/features/beneficiary/domain/entities/beneficiary_profile.dart` — BeneficiaryProfile entity
2. [ ] `lib/features/beneficiary/domain/entities/order_history_entry.dart` — OrderHistoryEntry entity + OrderHistoryEntryStatus enum
3. [ ] `lib/features/beneficiary/domain/entities/beneficiary_org_profile_update.dart` — BeneficiaryOrgProfileUpdate value object
4. [ ] `lib/features/beneficiary/domain/repositories/beneficiary_account_repository.dart` — BeneficiaryAccountRepository abstract interface
5. [ ] `lib/features/beneficiary/domain/usecases/watch_beneficiary_profile_usecase.dart` — WatchBeneficiaryProfileUseCase
6. [ ] `lib/features/beneficiary/domain/usecases/update_personal_info_usecase.dart` — UpdatePersonalInfoUseCase
7. [ ] `lib/features/beneficiary/domain/usecases/update_org_profile_usecase.dart` — UpdateOrgProfileUseCase
8. [ ] `lib/features/beneficiary/domain/usecases/watch_order_history_usecase.dart` — WatchOrderHistoryUseCase
9. [ ] `lib/features/beneficiary/data/models/beneficiary_profile_model.dart` — BeneficiaryProfileModel DTO
10. [ ] `lib/features/beneficiary/data/models/order_history_entry_model.dart` — OrderHistoryEntryModel DTO
11. [ ] `lib/features/beneficiary/data/datasources/beneficiary_account_remote_datasource.dart` — abstract + impl stub
12. [ ] `lib/features/beneficiary/data/repositories/beneficiary_account_repository_impl.dart` — BeneficiaryAccountRepositoryImpl stub
13. [ ] `lib/features/beneficiary/presentation/providers/beneficiary_account_provider.dart` — all @riverpod providers + OrderHistoryState + OrderHistoryNotifier
14. [ ] `lib/features/beneficiary/presentation/screens/beneficiary_account_screen.dart` — ConsumerStatefulWidget placeholder
15. [ ] `lib/features/beneficiary/presentation/screens/beneficiary_personal_information_screen.dart` — ConsumerStatefulWidget placeholder
16. [ ] `lib/features/beneficiary/presentation/screens/beneficiary_org_profile_screen.dart` — ConsumerStatefulWidget placeholder
17. [ ] `lib/features/beneficiary/presentation/screens/beneficiary_order_history_screen.dart` — ConsumerWidget placeholder

## Progress

- [ ] All 17 files pending implementation (stubs created this session)

## Decisions Made

- BeneficiaryAccountRemoteDatasource stub retains `firebase_auth` import as specified by the spec API contract; it is the only file in `features/beneficiary/` permitted to import Firebase packages
- OrderHistoryNotifier uses family parameter `build(String uid)` per Riverpod 2.x `@riverpod` class notifier pattern
- BatchModel import retained in repository impl stub to match spec signature (needed at implementation time for _toEntry mapping)
- BeneficiaryProfileModel.toDomain() stubbed with throw UnimplementedError() even though the spec shows a full implementation — per task instructions stubs only
- OrderHistoryEntryModel created as a plain Dart DTO (not Freezed) matching spec intent; toDomain() stubbed

## Blockers / Open Questions

- `BeneficiaryBottomNav` must be extracted from `beneficiary_dashboard_screen.dart` and that screen updated to use it — two-file change must be in the same PR as the account screens
- `BeneficiaryModel` needs 3 additive Freezed fields (`orgType`, `contactEmail`, `missionStatement`) added and build_runner re-run before the datasource can be wired
- `FirestoreService` needs `updateBeneficiary` and `getBeneficiaryMap` methods added before datasource impl can proceed
- GoRouter entries for `/beneficiary/account`, `/beneficiary/account/personal`, `/beneficiary/account/org`, `/beneficiary/account/orders` must be added to `lib/app/router.dart`
- `firestore.indexes.json` may not exist in the repo — engineer must create it with the composite index for `batches(beneficiaryId ASC, status ASC, createdAt DESC)` and flag it in the PR

## Handoff

After stubs are complete, implementation order recommended by spec open question §3:
1. Extend `BeneficiaryModel` with 3 new Freezed fields, run `dart run build_runner build`
2. Add `updateBeneficiary` and `getBeneficiaryMap` to `FirestoreService`
3. Implement `BeneficiaryAccountRemoteDatasourceImpl` bodies
4. Implement `BeneficiaryAccountRepositoryImpl` bodies
5. Wire all providers in `beneficiary_account_provider.dart`
6. Implement all four screens and two widgets per UI behaviour spec
7. Add GoRouter entries
8. Extract `BeneficiaryBottomNav` from dashboard screen
9. Run `flutter analyze` and `dart format .`
10. Submit PR for architect review

**Review needed from:** architect

## Final Summary

**Status:** Session closed 2026-06-04.

**Delivered:**
- Full Clean Architecture stack: domain entities, repository interface, use cases, data models, datasource impl, repository impl, Riverpod providers
- 4 screens: BeneficiaryAccountScreen, BeneficiaryPersonalInformationScreen, BeneficiaryOrgProfileScreen, BeneficiaryOrderHistoryScreen
- 2 widgets: BeneficiaryBottomNav, OrderHistoryCard
- Router: `/beneficiary/account`, `/beneficiary/account/personal`, `/beneficiary/account/org`, `/beneficiary/account/orders`
- 58 widget tests, all passing. `flutter analyze` clean.
- Photo upload wired (Firebase Storage). Form validation on all required fields.
- `storage.rules` updated: `users/{uid}/**` owner-only write rule added.

**Deferred (tracked as follow-ups):**
- OrderHistoryNotifier real implementation (currently UnimplementedError stub)
- GPS geolocation button (currently shows SnackBar)
- mealsReceived computed from impactMetrics/{uid}
- Role guard for /beneficiary/** router subtree
- Replace donor-domain UserProfileUpdate with beneficiary-scoped entity

**PR review outcome:** CHANGES REQUESTED by all three reviewers. 7 blocking findings documented in `docs/agent-runs/2026-06-04-qa-beneficiary-account-profile-merged.md`. Storage rules gap (HIGH) resolved in this session. Remaining blockers assigned to next session.
