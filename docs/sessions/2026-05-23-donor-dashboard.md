# Session: 2026-05-23 — donor-dashboard

**Date:** 2026-05-23  
**Member:** Kim Taeman  
**Agent:** flutter-engineer  
**Task:** Implement donor dashboard feature per SPEC-0002

---

## Context

All stubs already exist under `features/donor/`. The spec is at `tech-specs/0002-donor-dashboard.md` (status: APPROVED). The approved proposal is `tech-proposals/0002-donor-dashboard.md`.

Design reference: `Donor Dashboard (Cleaned Batch View).png` in the project root.

## Plan

1. Create `DonorMetrics` domain entity
2. Create `WatchActiveBatchesUsecase`
3. Fill `DonorRepository` interface (3 methods)
4. Fill `CreateBatchUsecase.call` and `GetDonorMetricsUsecase.call`
5. Fill `DonorRemoteDatasource` contract + impl (Firestore queries)
6. Implement `DonorRepositoryImpl` with Hive write-through cache
7. Write all Riverpod providers in `donor_provider.dart`
8. Open Hive boxes in `main.dart`
9. Create `DonorBottomNav` widget
10. Implement `DonorDashboardScreen` (header, welcome, metrics card, log button, batch list, bottom nav)
11. Scaffold `LogBatchScreen` and `BatchQrScreen` constructors
12. Patch `router.dart` with sub-routes
13. Run `dart run build_runner build --delete-conflicting-outputs`
14. Run `flutter analyze` + `dart format .`

## Progress

- [ ] DonorMetrics entity
- [ ] WatchActiveBatchesUsecase
- [ ] DonorRepository interface
- [ ] Use case call methods
- [ ] DonorRemoteDatasource
- [ ] DonorRepositoryImpl
- [ ] Riverpod providers
- [ ] Hive boxes in main.dart
- [ ] DonorBottomNav widget
- [ ] DonorDashboardScreen
- [ ] LogBatchScreen / BatchQrScreen scaffolds
- [ ] Router patch
- [ ] Build runner + analyze + format

## Decisions Made

- OQ-7 (Public Sans font): defer to platform default for now — no `google_fonts` dependency added
- OQ-8 (Batch display name): use `batch.id.substring(0, 8).toUpperCase()` as short code
- OQ-1 (whereNotIn + orderBy): sort client-side in repository to avoid Firestore index complexity
- OQ-2 (Hive openBox): add to `main.dart` before `runApp`
- OQ-3 (Firestore injection): inject `FirebaseFirestore.instance` directly in datasource provider

## Blockers / Open Questions

- None blocking implementation — all OQs resolved above

## Handoff

**Review needed from:** architect, qa-engineer
