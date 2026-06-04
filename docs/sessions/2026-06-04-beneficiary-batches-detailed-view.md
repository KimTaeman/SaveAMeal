# Session: 2026-06-04 — beneficiary-batches-detailed-view

**Date:** 2026-06-04
**Member:** khinnadiko
**Agent:** flutter-engineer
**Task:** Implement SPEC-0006 — DeliveryDetailScreen with IntakeRequestDetail entity, live map, and item list

---

## Context

SPEC-0006 is ACCEPTED. Proposal PROP-0006 is ACCEPTED (approved by ALORA).

The `beneficiary` feature folder already exists. This session adds new files to it and
modifies four existing files. The `DeliveryDetailScreen` at
`presentation/screens/delivery_detail_screen.dart` is currently a stub that renders only
the raw `batchId`. The route `/beneficiary/delivery/:batchId` is already registered in
`apps/mobile/lib/app/router.dart`.

Full spec: `tech-specs/0006-beneficiary-batches-detailed-view.md`

---

## Plan

### New domain entities (no build_runner needed — pure Dart)
1. ✅ `domain/entities/intake_item.dart` — stubbed, fully implementable as-is
2. ✅ `domain/entities/intake_request_detail.dart` — stubbed, fully implementable as-is
3. ✅ `domain/usecases/watch_intake_request_detail_usecase.dart` — fully implementable as-is

### Modify data layer
4. [ ] `domain/repositories/intake_repository.dart` — add `Stream<IntakeRequestDetail?> watchIntakeRequestDetail(String batchId)`
5. [ ] `data/models/intake_request_model.dart` — add `batchModelToDetailDomain(BatchModel batch)` mapper. **Note:** `_mapStatus` is currently private in `IntakeRequestModelX` — extract it to a package-accessible function (see spec implementation note)
6. [ ] `data/repositories/firestore_intake_repository.dart` — implement `watchIntakeRequestDetail` calling `_datasource.watchBatch(batchId)` + mapper

### Modify presentation layer
7. [ ] `presentation/providers/beneficiary_provider.dart` — add `watchIntakeRequestDetailUseCaseProvider` and `intakeRequestDetailProvider(batchId)` stream providers. Run `dart run build_runner build --delete-conflicting-outputs` after.
8. [ ] `presentation/widgets/driver_info_card.dart` — implement per spec UI layout (GoogleMap + driver row). Stub exists.
9. [ ] `presentation/widgets/batch_items_card.dart` — implement per spec UI layout (origin chip + item list). Stub exists.
10. [ ] `presentation/screens/delivery_detail_screen.dart` — rewrite stub as `ConsumerStatefulWidget` watching `intakeRequestDetailProvider(batchId)`. Handle all 5 screen states: loading, active, collected, cancelled, null/not-found.

### Fill test stubs
11. [ ] `test/unit/features/beneficiary/watch_intake_request_detail_usecase_test.dart`
12. [ ] `test/unit/features/beneficiary/intake_request_detail_mapper_test.dart`
13. [ ] `test/widget/features/beneficiary/delivery_detail_screen_test.dart`

---

## Progress

- [x] Spec ACCEPTED (PROP-0006 approved by ALORA)
- [x] `intake_item.dart` stub created
- [x] `intake_request_detail.dart` stub created
- [x] `watch_intake_request_detail_usecase.dart` stub created
- [x] `driver_info_card.dart` stub created
- [x] `batch_items_card.dart` stub created
- [x] Test stubs created
- [ ] Data layer modifications (steps 4–6)
- [ ] Provider additions + build_runner (step 7)
- [ ] Widget implementations (steps 8–9)
- [ ] Screen implementation (step 10)
- [ ] Tests filled in (steps 11–13)
- [ ] `flutter analyze` + `dart format .` clean
- [ ] PR submitted for architect/QA review

---

## Decisions Made

- `IntakeItem` and `IntakeRequestDetail` are plain Dart value types (no Freezed) — matching the existing `IntakeRequest` pattern in this feature
- `_mapStatus` extraction: move to top-level `mapIntakeStatus(String raw)` function in `intake_request.dart` and call from both `toDomain()` and `batchModelToDetailDomain()`
- `estimatedArrivalMinutes` and `cancellationReason` map to `null` in this iteration — fields not yet on `BatchModel`
- `DriverInfoCard.driverLocation` param typed as `Object?` in stub — replace with `DriverLocationModel?` (from `core/models/driver_location_model.dart`) when implementing

---

## Blockers / Open Questions

- None at scaffold time. All four proposal open questions resolved in spec.

---

## Handoff

The engineer implementing step 10 (`DeliveryDetailScreen`) must:
1. Watch both `intakeRequestDetailProvider(batchId)` AND `driverLocationProvider(detail.volunteerId)` — the second requires a non-null `volunteerId`
2. GoogleMap widget in `DriverInfoCard`: use `liteModeEnabled: true` on Android (check `Platform.isAndroid`) to render a static bitmap; set all gesture flags to false
3. The "En route" chip shows only when `driverLocation != null` — do NOT show a distance value (haversine deferred)
4. Run `dart run build_runner build --delete-conflicting-outputs` after adding providers to `beneficiary_provider.dart`

**Review needed from:** architect, qa-engineer
