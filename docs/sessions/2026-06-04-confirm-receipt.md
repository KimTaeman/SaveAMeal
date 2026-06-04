# Session: 2026-06-04 — confirm-receipt

**Date:** 2026-06-04  
**Member:** khinnadiko  
**Agent:** flutter-engineer  
**Task:** Implement confirm-receipt feature (SPEC-0008)

---

## Context

SPEC-0008 is drafted (status: DRAFT). PROP-0008 is drafted.
The feature is an extension of the existing `beneficiary` feature — no new feature folder.

Figma: modal full-screen confirm receipt screen with optional 1–5 star rating,
optional free-text feedback, and a "Report an Issue" secondary action.

Key architectural decisions:
- `beneficiaryId` from `authStateProvider` in the notifier — never from the screen
- Single Firestore partial update: `{ status: 'closed', rating?, feedback?, updatedAt }`
- Existing security rule permits this write (no rule changes needed)
- Offline: Firestore SDK queues writes natively — no Hive outbox
- `rate_delivery_screen.dart` stub is replaced in-place with `ConfirmReceiptScreen`

## Plan

1. **Domain layer**
   - Add `confirmReceipt({batchId, beneficiaryId, rating?, feedback?})` to `IntakeRepository`
   - Implement `ConfirmReceiptUseCase` (stub already created at `domain/usecases/confirm_receipt_usecase.dart`)

2. **Data layer**
   - Add `confirmReceipt({batchId, rating?, feedback?})` to `IntakeRemoteDatasource` abstract + impl
   - Add `confirmReceipt` method to `FirestoreService` (partial `batches/{batchId}` update)
   - Implement in `FirestoreIntakeRepository`

3. **Presentation layer**
   - Implement `ConfirmReceiptNotifier` in `confirm_receipt_provider.dart` (stub already created)
   - Run `dart run build_runner build --delete-conflicting-outputs` to generate `.g.dart`
   - Implement `ConfirmReceiptScreen` in `rate_delivery_screen.dart` (replace stub, rename class)
   - Modify `DeliveryDetailScreen`: add `_ConfirmReceiptButton` (status==delivered) and `_ConfirmationBanner` (status==closed)
   - Register `confirmReceiptUseCaseProvider` in `beneficiary_provider.dart`
   - Add route `/beneficiary/delivery/:batchId/confirm` to `router.dart`

4. **Tests**
   - Fill in `confirm_receipt_usecase_test.dart` (11 cases — see SPEC-0008)
   - Fill in `confirm_receipt_notifier_test.dart` (11 cases — see SPEC-0008)
   - Fill in `confirm_receipt_screen_test.dart` (10 cases — see SPEC-0008)
   - Add 8 cases to `delivery_detail_screen_test.dart`

5. **Cleanup**
   - `flutter analyze` — zero new warnings
   - `dart format .` — clean

## Progress

- [x] `ConfirmReceiptUseCase` stub created
- [x] `ConfirmReceiptNotifier` / `ConfirmReceiptState` stub created
- [x] Test stubs created (usecase, notifier, screen)
- [ ] `IntakeRepository.confirmReceipt` method added
- [ ] `IntakeRemoteDatasource.confirmReceipt` method added
- [ ] `FirestoreService.confirmReceipt` method added
- [ ] `FirestoreIntakeRepository.confirmReceipt` implemented
- [ ] `ConfirmReceiptNotifier` fully implemented
- [ ] `.g.dart` regenerated
- [ ] `ConfirmReceiptScreen` implemented (replaces rate_delivery_screen.dart stub)
- [ ] `DeliveryDetailScreen` modified
- [ ] Route added to router.dart
- [ ] `beneficiary_provider.dart` updated
- [ ] All tests passing
- [ ] `flutter analyze` clean
- [ ] `dart format .` clean

## Decisions Made

- `ConfirmReceiptUseCase` takes only `IntakeRepository` — no `AuthRepository` injection (ADR-0016)
- `rate_delivery_screen.dart` is replaced in-place, not deleted, to avoid dangling router import

## Blockers / Open Questions

- None at scaffolding time

## Handoff

Engineer: read SPEC-0008 at `tech-specs/0008-confirm-receipt.md` before starting.
All stub files are in place — fill them in layer by layer (domain → data → presentation → tests).
Run `dart run build_runner build --delete-conflicting-outputs` after implementing the provider.

**Review needed from:** qa-engineer, security-reviewer
