---
title: "0008: Confirm Receipt"
description: "Add a beneficiary-side tap-to-confirm action on DeliveryDetailScreen that transitions a batch from delivered to closed, providing an explicit acknowledgement step in the delivery loop."
---

# PROP-0008: Confirm Receipt

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-04
**Spec:** (pending approval)
**Approved by:** nadi

---

## Problem

The SaveAMeal delivery loop currently closes when the driver marks a batch `delivered` via `confirmDelivery` in `IntakeRepository`. From that point, the batch sits in `delivered` status indefinitely unless a beneficiary rating or feedback action explicitly transitions it to `closed`. There is no dedicated, mandatory beneficiary acknowledgement step — a beneficiary looking at `DeliveryDetailScreen` sees a batch in the `delivered` state but has no action to confirm they physically received the food.

This creates two concrete problems:

1. **Audit trail gap.** Donors and platform operators cannot distinguish between a batch that was genuinely received by the beneficiary and one where the driver marked delivery but the beneficiary was absent or the delivery was left unattended. The `delivered` status reflects the driver's action, not the beneficiary's acknowledgement.

2. **Trust deficit.** Beneficiaries have no in-app moment of closure. The delivery flow simply stops updating. For food-rescue operations tracked for impact reporting (donor reporting, NGO compliance), a beneficiary-confirmed `closed` status is materially different from a driver-marked `delivered` status.

The gap is confirmed in the current `DeliveryDetailScreen` implementation: the screen handles `IntakeStatus.cancelled` with a `_CancellationBanner` but has no conditional UI or action for `IntakeStatus.delivered`. The `IntakeRepository` interface exposes `confirmDelivery` for the driver and `toggleIntakeStatus` for availability toggling, but there is no `confirmReceipt` operation representing the beneficiary closing their side of the transaction.

The Firestore `batches` security rules already permit a beneficiary to write `status`, `rating`, `feedback`, and `updatedAt` when the current status is `delivered` or `closed`. No backend changes are required to unlock this capability.

---

## Proposed Solution

Add a prominent "Confirm Receipt" primary action button to `DeliveryDetailScreen`, visible only when `detail.status == IntakeStatus.delivered`. Tapping the button invokes a new `ConfirmReceiptUseCase` in the domain layer, which calls a new `confirmReceipt` method on `IntakeRepository`. The repository implementation writes `{ status: 'closed', updatedAt: <now> }` to the `batches` Firestore document, using the existing security rule permission set (`keys().hasOnly(['status', 'rating', 'feedback', 'updatedAt'])`).

The interaction model is optimistic: the UI transitions immediately to a confirmed/closed visual state before the Firestore write completes. If the write fails, the local state is rolled back and an error snackbar is shown. The optimistic update is persisted to the existing Hive cache so that the screen renders the `closed` state while offline; the Firestore write is retried when connectivity is restored.

Once `status` transitions to `closed`, the `watchIntakeRequestDetail` stream emits a new `IntakeRequestDetail` with `status == IntakeStatus.closed`, and the button disappears, replaced by a confirmation indicator (e.g. a `_ConfirmationBanner` analogous to `_CancellationBanner`).

This solution requires:

- A new `ConfirmReceiptUseCase` in the beneficiary domain layer (pure Dart, zero framework imports).
- A new `confirmReceipt({required String batchId, required String beneficiaryId})` method on the `IntakeRepository` abstract interface.
- An implementation in `FirestoreIntakeRepository` (data layer) that performs the Firestore document update.
- Hive cache invalidation for the affected batch key when the optimistic update is applied and when it is rolled back.
- A UI change to `DeliveryDetailScreen` in the presentation layer: one new conditional widget slot for the button, one new `_ConfirmationBanner` for the closed state.
- No new packages or Cloud Functions.

---

## Alternatives Considered

### A — Auto-close on a server-side timer (e.g. 24 hours after delivery)

A Cloud Function listens for `status == 'delivered'` writes on the `batches` collection and schedules a Cloud Tasks job. After 24 hours, if the status is still `delivered`, the function writes `status: 'closed'` automatically.

**Pros:**

- Zero beneficiary UI change required; the loop always closes, even if the beneficiary never opens the app.
- Audit trail is complete — every delivered batch eventually reaches `closed`.

**Cons:**

- Requires a new Cloud Function and Cloud Tasks configuration, which the project explicitly excludes (Firestore-only constraint).
- The `closed` status reflects a timeout, not genuine beneficiary acknowledgement — the audit trail is technically complete but semantically misleading.
- If the beneficiary opens the app after auto-close and tries to confirm, the write will fail because `status == 'closed'` is already outside the `delivered` guard in the security rule.
- Late-arriving driver `confirmDelivery` writes and auto-close writes could race if the timer fires while a driver update is in-flight.

**Effort:** L (large — Cloud Function infrastructure, Cloud Tasks setup, error handling for races).

**Rejected:** Conflicts with the Firestore-only constraint. Auto-close also does not produce genuine beneficiary acknowledgement.

---

### B — Photo-upload proof of receipt

The beneficiary taps "Confirm Receipt," opens the device camera or gallery, uploads a photo of the received food, and the upload triggers the `delivered → closed` transition.

**Pros:**

- Highest trust signal: photo evidence is verifiable and usable in donor or NGO compliance reports.
- Deters false confirmations.

**Cons:**

- Requires a new file-storage integration (Firebase Storage or equivalent), a new package dependency for image picking, and significant UI work (camera permission flow, upload progress, preview).
- Adds friction to an action that should be a single tap; beneficiaries in low-connectivity environments face a painful experience.
- Photo moderation and storage costs are out of scope for MVP.

**Effort:** XL (extra large — new storage dependency, new permissions, new upload infrastructure, UI complexity).

**Rejected:** Explicitly excluded by the product team. Out of scope for MVP.

---

### C — Email or SMS OTP confirmation

A push notification or SMS is sent to the beneficiary when the batch reaches `delivered`. The notification contains a one-time code. The beneficiary enters the code in the app to close the batch.

**Pros:**

- Two-factor-style confirmation; the beneficiary must actively respond, even without opening the app.
- Useful if the beneficiary does not have a smartphone (SMS path).

**Cons:**

- Requires an external messaging service (FCM push or an SMS gateway), new Cloud Function triggers, and OTP generation/validation logic — none of which are available under the Firestore-only constraint.
- OTP codes expire; if the beneficiary ignores the notification, the batch may never close (same problem as the status quo).
- Adds significant UX friction for a confirmation that should be effortless.

**Effort:** XL (extra large — messaging infrastructure, Cloud Functions, OTP lifecycle management).

**Rejected:** Explicitly excluded by the product team. Requires backend services beyond Firestore.

---

### D — Optional rating/feedback form as the closing action (current partial path)

The beneficiary is presented with a star-rating and optional feedback text field on `DeliveryDetailScreen` when status is `delivered`. Submitting the rating (even without stars selected) transitions the batch to `closed`. This is a soft confirmation bundled with feedback collection.

**Pros:**

- Simultaneously closes the loop and collects feedback — two goals, one interaction.
- No separate "Confirm Receipt" button is needed if the rating submission is the confirmation mechanism.
- Firestore security rules already permit `rating` and `feedback` writes under the same `delivered/closed` guard.

**Cons:**

- Conflates two concerns: "I received this delivery" (mandatory acknowledgement) and "I want to rate this experience" (optional, subjective). A beneficiary who does not want to rate is forced to interact with a form to close a batch.
- The confirmation becomes non-obvious: if the form is dismissible, the batch may never reach `closed`. If the form is mandatory, it adds friction where none should exist.
- Rating/feedback is a separable feature that can be added after the confirm-receipt mechanism is in place. Bundling them couples two independently useful features.
- The spec for this proposal would grow to cover both UI concerns simultaneously.

**Effort:** M (medium — same domain and data work as the proposed solution, plus rating/feedback form UI).

**Deferred, not rejected:** Rating/feedback can be designed as a separate, non-blocking follow-up action after `closed` is reached, in a subsequent proposal. The proposed solution (a single "Confirm Receipt" button) deliberately does not preclude rating/feedback — those fields remain writable under the existing `closed` security rule and can be added in a follow-on feature.

---

## Open Questions

1. **Should confirmation be mandatory before rating/feedback?** If a rating/feedback feature is added in a future proposal, should it be gated behind `status == closed` (i.e. the beneficiary must confirm receipt before rating), or should rating be accessible from `status == delivered` in parallel with the confirm button? Making confirmation a prerequisite enforces data integrity (you cannot rate a delivery you have not confirmed receiving) but increases friction. Making them parallel allows ratings to be collected even if the beneficiary never explicitly confirms.

2. **What happens if the beneficiary never confirms — does status stay `delivered` forever?** With the proposed solution, if the beneficiary never opens the app after delivery, the batch remains `delivered` indefinitely. Is this acceptable for MVP? If not, should a fallback timeout (Option A) be scheduled as a background task at a later phase, or should the ops team have an admin tool to bulk-close stale `delivered` batches after a defined period?

3. **Offline behaviour — what is the retry boundary?** The optimistic Hive write immediately reflects `closed` locally. If the user is offline and then uninstalls the app before reconnecting, the Firestore write is lost and the batch stays `delivered` in the server. Should the app queue the pending write in a Hive "outbox" for retry on next launch, or is a best-effort single retry on reconnect sufficient for MVP?

4. **Who is the `beneficiaryId` for the write?** `IntakeRequestDetail` carries `beneficiaryId`, which is available in `DeliveryDetailScreen` via the watched stream. The `confirmReceipt` call should pass both `batchId` and `beneficiaryId` to allow the repository to validate ownership before writing. Should the use case read `beneficiaryId` from a session/auth provider, or should the presentation layer pass it explicitly from the already-loaded `IntakeRequestDetail`?

---

## Acceptance Criteria

**Domain layer**

- `IntakeRepository` declares a new method `Future<void> confirmReceipt({required String batchId, required String beneficiaryId})`.
- A new `ConfirmReceiptUseCase` in `domain/usecases/` has a `call` method that delegates to `IntakeRepository.confirmReceipt`. It has zero Flutter or Firestore imports.
- `ConfirmReceiptUseCase` is unit-testable with a mock repository: given a mock that completes normally, `call` returns without error; given a mock that throws, the exception propagates.

**Data layer**

- `FirestoreIntakeRepository` implements `confirmReceipt` by writing `{ 'status': 'closed', 'updatedAt': FieldValue.serverTimestamp() }` to the `batches` document identified by `batchId`.
- The implementation validates that the caller is the batch's `beneficiaryId` at the Firestore security rule level (the rule already enforces this); no additional client-side ownership check is required beyond passing `beneficiaryId` as a parameter for logging/tracing purposes.
- The Hive cache entry for `batchId` is invalidated (deleted or updated to `closed`) synchronously before the Firestore call, implementing the optimistic update.
- On Firestore write failure, the Hive cache entry is restored to `delivered` and the error is rethrown.

**Presentation layer**

- `DeliveryDetailScreen` renders a prominent primary button labelled "Confirm Receipt" when and only when `detail.status == IntakeStatus.delivered`.
- Tapping the button calls `ConfirmReceiptUseCase` via a Riverpod provider; the button transitions to a loading state (disabled, shows a progress indicator) during the async call.
- On success, the button disappears and a `_ConfirmationBanner` is shown (analogous to `_CancellationBanner`) indicating the receipt has been confirmed.
- On failure, the button returns to its active state and an error snackbar is displayed.
- When `detail.status == IntakeStatus.closed` and the detail was not just confirmed in the current session (i.e. on navigation back to a closed batch), `_ConfirmationBanner` is shown and no button is rendered.
- All colours use `cs.*` or `ac.*` — no hardcoded colour values.
- All text styles use `Theme.of(context).textTheme.*` — no hardcoded font sizes.
- All spacing uses the project spacing scale — no magic numbers.

**Firestore**

- No new Firestore security rules are required; the write uses the existing `keys().hasOnly(['status', 'rating', 'feedback', 'updatedAt'])` permission on `batches` documents where `status in ['delivered', 'closed']`.

**Tests**

- A widget test for `DeliveryDetailScreen` covers: button is visible when `status == delivered`; button is absent when `status == open`, `claimed`, `pickedUp`, `cancelled`, or `closed`; tapping the button triggers the use case; `_ConfirmationBanner` is shown when `status == closed`.
- A unit test for `ConfirmReceiptUseCase` verifies delegation to the repository with correct `batchId` and `beneficiaryId` arguments.

**Architecture constraints**

- `DeliveryDetailScreen` imports from `domain/` and `presentation/` only — no import of any `data/` type.
- `ConfirmReceiptUseCase` imports only from `domain/` — no Flutter, Riverpod, or Firestore imports.
- `flutter analyze` reports zero new warnings after implementation.
- `dart format .` is run before the PR is submitted.
