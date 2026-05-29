# Session: 2026-05-26 — beneficiary-intake-status

**Date:** 2026-05-26
**Member:** khinnadiko
**Agent:** flutter-engineer
**Task:** Implement the beneficiary-intake-status feature per SPEC-0004

---

## Context

SPEC-0004 is approved. All stub files have been scaffolded. The feature spans two feature folders:
- `lib/features/beneficiary/` — domain entities, repository interface, use cases, data layer, presentation (home screen, delivery detail, widgets)
- `lib/features/volunteer/` — volunteer queue screen, QR delivery scanner screen, pending request card widget

The implementation reuses the existing `batches` Firestore collection (no new `intakes` collection). `IntakeRequest` is a domain projection over `BatchModel`, filtered to `beneficiaryId == currentUser.uid`. The Accepting/Full-Busy toggle writes `intakeStatus` on the `beneficiaries/{id}` Firestore document.

Spec: [SPEC-0004](../../tech-specs/0004-beneficiary-intake-status.md)
Proposal: [PROP-0004](../../tech-proposals/0004-beneficiary-intake-status.md)
ADR: [0007](../decisions/0007-intake-status-realtime-strategy.md)

---

## Plan

1. **Domain layer** — already scaffolded; no changes needed unless open questions are resolved
   - `intake_request.dart` — `IntakeRequest` entity + `IntakeStatus` + `BeneficiaryIntakeAvailability` enums
   - `intake_repository.dart` — abstract interface
   - Four use case files

2. **Data layer**
   - Add `cancelled` to `BatchStatus` enum in `core/models/batch_model.dart`
   - Add `volunteerName: String?` field to `BatchModel`
   - Implement `IntakeRemoteDatasourceImpl` in `intake_remote_datasource.dart` (Firestore queries)
   - Run `dart run build_runner build` after editing `intake_request_model.dart`
   - Implement all methods in `FirestoreIntakeRepository`

3. **Presentation — Beneficiary**
   - Fill in `beneficiary_provider.dart` with `@riverpod` providers per spec
   - Rewrite `beneficiary_dashboard_screen.dart` → `BeneficiaryHomeScreen` per Figma layout
   - Implement `delivery_detail_screen.dart`
   - Implement four widgets: `intake_status_toggle`, `active_delivery_card`, `visibility_inactive_card`, `how_pausing_works_section`

4. **Presentation — Volunteer**
   - Implement `volunteer_queue_screen.dart`
   - Implement `volunteer_delivery_scanner_screen.dart`
   - Implement `pending_request_card.dart`

5. **Router** — add `/beneficiary/delivery/:batchId`, `/volunteer`, `/volunteer/scan/:batchId` routes to `app/router.dart`

6. **Firestore Security Rules** — add rules from spec to `firestore.rules`

7. **Tests** — 15 test files per spec test plan

---

## Progress

- [x] Domain entities and enums (`intake_request.dart`)
- [x] Repository interface (`intake_repository.dart`)
- [x] Four use case stubs
- [x] `IntakeRequestModel` Freezed model stub
- [x] `IntakeRemoteDatasource` abstract interface stub
- [x] `FirestoreIntakeRepository` stub
- [x] `DeliveryDetailScreen` stub
- [x] Four beneficiary widget stubs
- [x] `VolunteerQueueScreen` stub
- [x] `VolunteerDeliveryScannerScreen` stub
- [x] `PendingRequestCard` stub
- [ ] Add `cancelled` + `volunteerName` to `BatchModel`
- [ ] Implement `IntakeRemoteDatasourceImpl`
- [ ] Run `build_runner` for `IntakeRequestModel`
- [ ] Implement `FirestoreIntakeRepository` methods
- [ ] Fill in `beneficiary_provider.dart`
- [ ] Implement `BeneficiaryHomeScreen` (Figma layout)
- [ ] Implement `DeliveryDetailScreen`
- [ ] Implement all widgets
- [ ] Implement volunteer screens
- [ ] Update router
- [ ] Deploy Firestore Security Rules
- [ ] Write 15 test files

---

## Decisions Made

- **No new `intakes` collection** — `IntakeRequest` is a read projection over `batches`. Keeps single source of truth.
- **`cancelled` added to `BatchStatus`** — additive, non-breaking for existing switch consumers.
- **`volunteerName` denormalised onto batch document** — avoids a join on every beneficiary read. Open question: stale-name risk.
- **`beneficiaries/{id}.intakeStatus` is the single source of truth** for the Accepting/Full-Busy toggle. `UserModel.status` (`BeneficiaryStatus`) is not read or written by this feature.
- **Raw `batchId` in QR** — simpler; security enforced by Firestore Rules. One-time token deferred.
- **`role == 'driver'`** in Security Rules — matches existing `UserRole.driver` enum value.

---

## Blockers / Open Questions

- ~~`BeneficiaryStatus` on `UserModel` vs `intakeStatus` on `beneficiaries` doc~~ — **resolved**: `beneficiaries/{id}.intakeStatus` is the single source of truth. Do not read or write `UserModel.status` in this feature.
- `portions` field on `BatchModel` — currently approximated as `items.length`; confirm with product owner.
- QR one-time token safety — deferred, flagged in spec open questions.
- `UserRole.driver` vs `volunteer` terminology — resolve before deploying Security Rules.

---

## Handoff

Next agent (flutter-engineer) should start with step 2 (Data layer). Resolve the `BeneficiaryStatus` source-of-truth question first — it blocks `FirestoreIntakeRepository.toggleIntakeStatus` and `beneficiary_provider.dart`.

After implementation, submit for review to **qa-engineer** (test coverage) and **security-reviewer** (Firestore Security Rules).

**Review needed from:** qa-engineer, security-reviewer
