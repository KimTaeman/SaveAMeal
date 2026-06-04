---
title: "0008: Confirm Receipt"
description: "Beneficiary-side tap-to-confirm action that closes a batch from delivered to closed, with optional 1–5 star rating and text feedback written in a single Firestore update."
---

# SPEC-0008: Confirm Receipt

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-04
**Proposal:** [PROP-0008](../tech-proposals/0008-confirm-receipt.md)
**Approved by:** nadi

---

## Overview

When a driver marks a batch `delivered`, the loop currently stalls — the beneficiary has no in-app action to acknowledge physical receipt. This spec closes that gap by:

1. Adding a **"Confirm Receipt"** `FilledButton` to the existing `DeliveryDetailScreen`, visible exclusively when `detail.status == IntakeStatus.delivered`.
2. Navigating to a new `ConfirmReceiptScreen` (replacing the `rate_delivery_screen.dart` stub) at the route `/beneficiary/delivery/:batchId/confirm`.
3. On that screen the beneficiary may optionally leave a 1–5 star rating and free-text feedback, then tap **"Confirm Receipt"** to write `{ status: 'closed', rating?, feedback?, updatedAt }` in a single Firestore partial update.
4. Once submitted, the stream for `watchIntakeRequestDetail` emits `status == closed`, the CTA disappears, and `DeliveryDetailScreen` renders a `_ConfirmationBanner` instead.

The feature requires no new Cloud Functions, no new Firestore security rules, and no new pub.dev packages. The domain layer acquires one new use case and one new method on `IntakeRepository`; all other layers extend existing patterns.

The `beneficiaryId` for the Firestore write is read from `authStateProvider` inside the Riverpod notifier — it is never passed from the screen as a constructor argument.

---

## Architecture

```mermaid
flowchart TD
    subgraph Presentation
        A[DeliveryDetailScreen\n+ Confirm Receipt button\n+ _ConfirmationBanner]
        B[ConfirmReceiptScreen\nConsumerStatefulWidget]
        C[ConfirmReceiptNotifier\n@riverpod family batchId]
        D[ConfirmReceiptState\nrating, feedback,\nisSubmitting, error]
    end

    subgraph Domain
        E[ConfirmReceiptUseCase\npure Dart]
        F[IntakeRepository interface\n+ confirmReceipt]
    end

    subgraph Data
        G[FirestoreIntakeRepository\nimplements confirmReceipt]
        H[IntakeRemoteDatasource\n+ confirmReceipt]
        I[IntakeRemoteDatasourceImpl\ncalls FirestoreService]
        J[FirestoreService\npartial update batches/batchId]
    end

    subgraph Router
        K[router.dart\n/beneficiary/delivery/:batchId/confirm]
    end

    A -->|context.push| K
    K --> B
    B --> C
    C --> D
    C -->|call| E
    E --> F
    F -.implements.-> G
    G --> H
    H -.implements.-> I
    I --> J
```

---

## File map

| Action  | Path                                                                                        | Responsibility                                                                                                             |
| ------- | ------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| Modify  | `apps/mobile/lib/features/beneficiary/domain/repositories/intake_repository.dart`           | Add `confirmReceipt` abstract method                                                                                       |
| Create  | `apps/mobile/lib/features/beneficiary/domain/usecases/confirm_receipt_usecase.dart`         | New use case; pure Dart; reads `beneficiaryId` via constructor-injected `uid` parameter resolved by the provider           |
| Modify  | `apps/mobile/lib/features/beneficiary/data/datasources/intake_remote_datasource.dart`       | Add `confirmReceipt` to abstract class and `IntakeRemoteDatasourceImpl`                                                    |
| Modify  | `apps/mobile/lib/features/beneficiary/data/repositories/firestore_intake_repository.dart`   | Implement `confirmReceipt`; call datasource                                                                                |
| Create  | `apps/mobile/lib/features/beneficiary/presentation/providers/confirm_receipt_provider.dart` | `ConfirmReceiptNotifier` (`@riverpod` family); `ConfirmReceiptState`; reads `uid` from `authStateProvider`                 |
| Replace | `apps/mobile/lib/features/beneficiary/presentation/screens/rate_delivery_screen.dart`       | Full replacement with `ConfirmReceiptScreen` implementation; same file path, class renamed to `ConfirmReceiptScreen`       |
| Modify  | `apps/mobile/lib/features/beneficiary/presentation/screens/delivery_detail_screen.dart`     | Add `_ConfirmReceiptButton` when `status == delivered`; add `_ConfirmationBanner` when `status == closed`; navigate on tap |
| Modify  | `apps/mobile/lib/app/router.dart`                                                           | Add `GoRoute` for `delivery/:batchId/confirm` inside `/beneficiary` subtree; import `ConfirmReceiptScreen`                 |
| Modify  | `apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_provider.dart`     | Register `confirmReceiptUseCaseProvider`                                                                                   |
| Create  | `apps/mobile/test/unit/features/beneficiary/confirm_receipt_usecase_test.dart`              | Unit tests for `ConfirmReceiptUseCase`                                                                                     |
| Create  | `apps/mobile/test/unit/features/beneficiary/confirm_receipt_notifier_test.dart`             | Unit tests for `ConfirmReceiptNotifier`                                                                                    |
| Create  | `apps/mobile/test/widget/features/beneficiary/confirm_receipt_screen_test.dart`             | Widget tests for `ConfirmReceiptScreen`                                                                                    |
| Modify  | `apps/mobile/test/widget/features/beneficiary/delivery_detail_screen_test.dart`             | ADD new test cases for `delivered`/`closed` status UI                                                                      |

---

## API contracts

### 1. `IntakeRepository` — new method (domain layer)

```dart
// lib/features/beneficiary/domain/repositories/intake_repository.dart

/// Closes the batch and writes optional rating/feedback in a single Firestore
/// partial update.
///
/// [beneficiaryId] is resolved from the auth session by the use case's caller
/// (the Riverpod notifier); it is passed here for logging and tracing only.
/// Firestore security rules enforce ownership independently.
///
/// [rating]   — 1–5; null if the beneficiary did not leave a rating.
/// [feedback] — free text; null if the beneficiary did not leave feedback.
Future<void> confirmReceipt({
  required String batchId,
  required String beneficiaryId,
  int? rating,
  String? feedback,
});
```

### 2. `IntakeRemoteDatasource` — new method (data layer)

```dart
// lib/features/beneficiary/data/datasources/intake_remote_datasource.dart

/// Performs the Firestore partial update. beneficiaryId is intentionally
/// omitted here — it is not written to the document; Firestore rules
/// enforce caller identity via Firebase Auth.
Future<void> confirmReceipt({
  required String batchId,
  int? rating,
  String? feedback,
});
```

`IntakeRemoteDatasourceImpl.confirmReceipt` delegates to `_firestoreService.confirmReceipt(...)`, which executes:

```dart
// Pseudocode for FirestoreService implementation (data layer only)
await _firestore.collection('batches').doc(batchId).update({
  'status': 'closed',
  if (rating != null) 'rating': rating,
  if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
  'updatedAt': FieldValue.serverTimestamp(),
});
```

### 3. `ConfirmReceiptUseCase` (domain layer — pure Dart)

```dart
// lib/features/beneficiary/domain/usecases/confirm_receipt_usecase.dart

// Pure Dart use case — zero Flutter, Riverpod, or Firestore imports.

import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';

class ConfirmReceiptUseCase {
  const ConfirmReceiptUseCase(this._repository);

  final IntakeRepository _repository;

  Future<void> call({
    required String batchId,
    required String beneficiaryId,
    int? rating,
    String? feedback,
  }) => _repository.confirmReceipt(
        batchId: batchId,
        beneficiaryId: beneficiaryId,
        rating: rating,
        feedback: feedback,
      );
}
```

Design note on `beneficiaryId` resolution: the `ConfirmReceiptNotifier` reads `uid` from `authStateProvider` and passes it as the `beneficiaryId` argument to the use case's `call` method. The use case itself remains a pure Dart class with no dependency on `AuthRepository` or any Riverpod type. This keeps the domain layer free of framework and cross-feature dependencies while satisfying the "auth session, not screen parameter" requirement.

### 4. `ConfirmReceiptState` and `ConfirmReceiptNotifier` (presentation layer)

```dart
// lib/features/beneficiary/presentation/providers/confirm_receipt_provider.dart

part 'confirm_receipt_provider.g.dart';

class ConfirmReceiptState {
  const ConfirmReceiptState({
    this.rating = 0,       // 0 = unrated; 1–5 = star rating
    this.feedback = '',
    this.isSubmitting = false,
    this.error,
    this.submitted = false,
  });

  final int rating;
  final String feedback;
  final bool isSubmitting;
  final String? error;
  final bool submitted;   // true after a successful confirmReceipt call

  ConfirmReceiptState copyWith({
    int? rating,
    String? feedback,
    bool? isSubmitting,
    String? error,
    bool? submitted,
  });
}

@riverpod
class ConfirmReceiptNotifier extends _$ConfirmReceiptNotifier {
  // batchId is the family parameter — one notifier instance per screen.

  @override
  ConfirmReceiptState build(String batchId);

  void setRating(int value);
    // If value == state.rating, sets rating to 0 (deselect).
    // Otherwise sets rating to value (1–5).

  void setFeedback(String value);
    // Updates feedback text; trims to 300 chars.

  Future<void> submit();
    // 1. Guard: if isSubmitting, return immediately (in-flight guard).
    // 2. Set isSubmitting = true, error = null.
    // 3. Read uid from authStateProvider; if null, set error and return.
    // 4. Call ConfirmReceiptUseCase.call(batchId, uid, rating, feedback).
    //    - rating: state.rating == 0 ? null : state.rating
    //    - feedback: state.feedback.trim().isEmpty ? null : state.feedback.trim()
    // 5. On success: set submitted = true, isSubmitting = false.
    // 6. On error: set error = e.toString(), isSubmitting = false.
}
```

The provider is declared with `@riverpod` code-gen. The family parameter `batchId` isolates each screen's notifier so that concurrent navigation does not share state.

---

## Firestore schema

Collection: `batches`, document: `{batchId}`

Partial update (Firestore `update()` call — only the listed fields are touched):

| Field       | Dart type | Firestore type | Value written                                         |
| ----------- | --------- | -------------- | ----------------------------------------------------- |
| `status`    | `String`  | String         | `'closed'`                                            |
| `rating`    | `int?`    | Number         | 1–5, or field omitted if `null`                       |
| `feedback`  | `String?` | String         | free text ≤ 300 chars, or field omitted if null/empty |
| `updatedAt` | —         | Timestamp      | `FieldValue.serverTimestamp()`                        |

No new Firestore security rules are required. The existing rule permits beneficiaries to write `keys().hasOnly(['status', 'rating', 'feedback', 'updatedAt'])` when the batch's current `status` is `'delivered'` or `'closed'`. Client-side ownership is validated at the stream layer by `watchIntakeRequestDetail` (which already returns `null` for batches where `batch.beneficiaryId != currentUser.uid`). If the update is rejected by Firestore (permission denied), the exception propagates to the notifier's error state.

---

## Screen layout — `ConfirmReceiptScreen`

The screen is a full-screen route (`ConsumerStatefulWidget`) wrapped in the project's bottom navigation bar (Home / Track / Impact / Account; **Track tab active**). It accepts `batchId` as a constructor parameter; `IntakeRequestDetail` is NOT passed — the provider resolves all needed data.

Layout inside `Scaffold.body` is a `SingleChildScrollView` containing a single white `Card` with the following children in order:

1. **Icon** — `CircleAvatar` (or `Container` with circular shape), background `ac.success.withOpacity(0.15)`, icon `Icons.inventory_2_outlined` (archive/box), icon colour `ac.success`, size 56 px diameter.
2. **Title** — `"Confirm Receipt"`, `textTheme.titleLarge`, `fontWeight: FontWeight.bold`, centred.
3. **Subtitle** — `"Please confirm that your delivery has arrived and let us know how it went."`, `textTheme.bodyMedium`, colour `cs.onSurfaceVariant`, centred.
4. **Info tile** — `Container` with `color: ac.brandLight.withOpacity(0.15)` (beige/tan approximation via brandLight at low opacity), rounded corners, two rows:
   - Row 1 label `"Order #"` + value = first 8 characters of `batchId` uppercased, prefixed `#` (e.g. `#B001ABCD`).
   - Row 2 label `"Date"` + value = `detail.createdAt` formatted as `"MMM dd, yyyy"` (e.g. `"Oct 24, 2023"`). Use `intl` package `DateFormat` — do NOT hardcode a date string.
5. **Divider** — `Divider(height: Spacing.lg)`.
6. **Rating label** — `"How was the delivery experience?"`, `textTheme.bodyMedium`, centred.
7. **Star row** — `Row` with 5 `IconButton` widgets. For index `i` in 1..5:
   - `icon`: `state.rating >= i ? Icons.star : Icons.star_border`
   - `color`: `ac.success`
   - `onPressed`: `notifier.setRating(i)`
   - `iconSize`: 32.0
   - `padding`: `EdgeInsets.zero`
8. **Feedback label** — `"Additional Feedback (Optional)"`, `textTheme.labelMedium`.
9. **TextField** — `maxLines: 5`, `minLines: 3`, `maxLength: 300`, `keyboardType: TextInputType.multiline`, `hintText: "Tell us more about your experience…"`, `onChanged: notifier.setFeedback`.
10. **Primary CTA** — `FilledButton.icon`, full width (`SizedBox.expand` or `double.infinity`), `icon: Icon(Icons.check_circle_outline)`, label `"Confirm Receipt"`, `style: FilledButton.styleFrom(backgroundColor: ac.success, foregroundColor: ac.onSuccess)`, disabled (`onPressed: null`) while `state.isSubmitting`, replaced with `CircularProgressIndicator` in the button's child when `state.isSubmitting`.
11. **Secondary CTA** — `OutlinedButton`, full width, text `"Report an Issue"`, `style: OutlinedButton.styleFrom(foregroundColor: ac.success, side: BorderSide(color: ac.success))`. `onPressed` navigates to a placeholder route (or calls `ScaffoldMessenger.of(context).showSnackBar(...)` with `"Coming soon"`) — destination is out of scope for this spec.

All spacing between items uses `SizedBox(height: Spacing.sm)` or `Spacing.md` from the spacing scale. No magic numbers.

---

## Test plan

| Test file                                                           | Covers                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| ------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `test/unit/features/beneficiary/confirm_receipt_usecase_test.dart`  | (1) `call` delegates to `IntakeRepository.confirmReceipt` with exact `batchId`, `beneficiaryId`, `rating`, `feedback` args; (2) propagates exception thrown by the mock repository; (3) passes `rating: null` and `feedback: null` when both are omitted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `test/unit/features/beneficiary/confirm_receipt_notifier_test.dart` | (1) initial state: `rating == 0`, `feedback == ''`, `isSubmitting == false`, `error == null`, `submitted == false`; (2) `setRating(3)` sets `rating = 3`; (3) `setRating(3)` a second time deselects → `rating = 0`; (4) `setRating(5)` then `setRating(2)` sets `rating = 2`; (5) `setFeedback` updates text, trims at 300 chars; (6) `submit` sets `isSubmitting = true` then `false` on success; (7) `submit` sets `submitted = true` on success; (8) `submit` sets `error` and re-enables button (`isSubmitting = false`) on repository exception; (9) double-`submit` guard: second call while `isSubmitting == true` returns immediately without calling use case a second time; (10) `rating == 0` passes `rating: null` to use case; (11) empty feedback passes `feedback: null` to use case |
| `test/widget/features/beneficiary/confirm_receipt_screen_test.dart` | (1) renders title `"Confirm Receipt"` and subtitle; (2) renders 5 star `IconButton`s, all unfilled initially; (3) tapping star 3 fills stars 1–3 and leaves 4–5 unfilled; (4) tapping star 3 again deselects → all unfilled; (5) primary CTA labelled `"Confirm Receipt"` is present; (6) primary CTA is disabled and shows `CircularProgressIndicator` when `isSubmitting == true`; (7) on `submitted == true` the screen pops (verify `Navigator.of(context).canPop()` or check route absence); (8) on `error != null` a `SnackBar` is shown with the error text; (9) `"Report an Issue"` `OutlinedButton` is present and tappable without throwing; (10) order `#` info tile shows first 8 chars of batchId uppercased                                                                            |
| `test/widget/features/beneficiary/delivery_detail_screen_test.dart` | **ADD** to existing file: (1) `"Confirm Receipt"` button is visible when `status == IntakeStatus.delivered`; (2) button is absent when `status == IntakeStatus.open`; (3) button is absent when `status == IntakeStatus.dispatched`; (4) button is absent when `status == IntakeStatus.cancelled`; (5) button is absent when `status == IntakeStatus.closed`; (6) tapping the button calls `context.push('/beneficiary/delivery/b_001/confirm')` — verify navigation (use `GoRouter` with a `MockGoRouter` or `ProviderScope` override with a stub); (7) `_ConfirmationBanner` containing text `"Receipt confirmed"` (or equivalent banner copy) is shown when `status == IntakeStatus.closed`; (8) `_ConfirmationBanner` is absent when `status != closed`                                          |

---

## Out of scope

- **"Report an Issue" destination** — the button must be rendered and tappable but its target route is a future spec. For MVP, tapping shows a `"Coming soon"` snackbar or navigates to a stub.
- **Post-close re-rating** — once `status == closed`, the rating cannot be edited. No UI or backend path supports overwriting a submitted rating.
- **Auto-close timer for stale `delivered` batches** — ADR-0015 explicitly deferred Option 2 (Cloud Function timer). This spec does not implement any fallback timer.
- **Photo upload proof of receipt** — explicitly excluded by the product team (see PROP-0008 Option B).
- **Email/SMS OTP confirmation** — explicitly excluded by the product team (see PROP-0008 Option C).
- **Hive optimistic-write outbox** — resolved open question 3 from PROP-0008: the Firestore SDK queues writes natively when offline. No manual Hive outbox or retry queue is implemented. The button shows a loading state and then success even while offline; Firestore flushes the queued write on reconnect.
- **`RateDeliveryUseCase` / `BeneficiaryRepository.rateDelivery` removal** — these are live interfaces serving a separate concern and must not be deleted as part of this feature. Removal is a separate architectural decision.
- **`ConfirmDeliveryUseCase` (driver-side)** — unrelated to this feature; do not modify or delete.
- **Hive cache invalidation for `deliveryHistoryPage`** — the paginated history cache from SPEC-0007 does not need to be invalidated; the `watchIntakeRequestDetail` stream update is sufficient to refresh the live detail view.

---

## Open questions

All PROP-0008 open questions are resolved:

1. **Rating gating** — rating and confirmation happen simultaneously on `ConfirmReceiptScreen`. Rating is optional; confirmation is not gated behind a prior action.
2. **Stale `delivered` batches** — acceptable for MVP. Stale batches remain `delivered` indefinitely. No auto-close timer is implemented (ADR-0015).
3. **Offline retry boundary** — Firestore SDK handles queuing. No manual outbox.
4. **`beneficiaryId` source** — `authStateProvider` via the Riverpod notifier; never passed from the screen's loaded `IntakeRequestDetail`.

No new open questions at spec authoring time.
