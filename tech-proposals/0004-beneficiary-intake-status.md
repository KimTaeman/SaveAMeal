---
title: "0004: Beneficiary Intake Status"
description: "Add automated, role-gated status tracking for food-intake requests so beneficiaries can monitor progress and volunteers can manage their delivery queue — with no manual staff intervention."
---

# PROP-0004: Beneficiary Intake Status

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-05-26
**Spec:** —
**Approved by:** ALORA

---

## Problem

The SaveAMeal app currently has no mechanism for tracking the lifecycle of a food-intake request after it is submitted. This creates a multi-sided coordination failure in the three-party marketplace (Donor → Volunteer → Beneficiary):

- **Beneficiaries** submit a request but receive no feedback. They cannot tell whether a volunteer has accepted their delivery, is en route, or has completed it. The only recourse is out-of-band contact, which reintroduces the NGO-staff bottleneck the platform is designed to eliminate.
- **Volunteers (Drivers)** have no queue surface that lists accepted and open requests. There is no in-app mechanism to accept a job or to record delivery completion — both happen out-of-band today.
- The previous design of this proposal (v1) required a manual "staff" actor to approve every request before it could move forward. This contradicts the core product premise: **SaveAMeal is a fully automated marketplace**. Introducing a staff approval gate replicates the NGO bottleneck in digital form.

The root technical gap is the absence of:
1. A `status` field on the intake document that tracks where each request is in its lifecycle.
2. A real-time mechanism to push state changes to listening beneficiary clients.
3. An automated transition path driven by Volunteer actions (job acceptance, QR delivery confirmation) instead of manual staff decisions.

The feature must satisfy two hard constraints:

1. **Real-time updates** — a status change triggered by a Volunteer action must reach the Beneficiary's device without requiring a manual refresh.
2. **Role-based visibility** — a given intake record may only be read by the Beneficiary who submitted it and by the Volunteer assigned to it. Other users must not see the record.

---

## Goals

- Define a typed, automated status state machine: `pending` → `dispatched` → `collected`; with a `cancelled` terminal state reachable from `pending` or `dispatched`.
- Add `status`, `volunteerId`, and optional `cancellationReason` fields to the intake domain entity and Firestore document.
- Trigger `pending → dispatched` automatically when a Volunteer taps "Accept Job" from the volunteer queue screen.
- Trigger `dispatched → collected` automatically when a Volunteer scans the Beneficiary's QR code at the point of delivery.
- Expose a real-time `Stream<IntakeRequest>` per Beneficiary so status changes surface immediately on their device without a pull-to-refresh.
- Provide a Volunteer queue screen that lists open (`pending`) requests and their own accepted (`dispatched`) requests, with actions to accept and confirm delivery.
- Enforce role-based read/write rules so only the requesting Beneficiary and the assigned Volunteer can read a given intake document, and only a Volunteer can write status transitions.
- Keep the Domain layer free of Firestore, Flutter, or any backend imports — all real-time behaviour is wired via repository interfaces returning `Stream`.

---

## Non-goals

- Manual staff approval steps — the entire lifecycle is driven by Volunteer and Beneficiary actions only.
- Push notifications (FCM) triggered by status changes — the app must be foregrounded to receive updates. Notifications are a separate feature.
- Full audit history or event log beyond the current status field.
- Analytics or aggregate reporting on intake throughput.
- Volunteer assignment routing (auto-matching a specific volunteer to a request) — the first iteration lets any available Volunteer self-select from the open queue.
- Offline mutation from Volunteers — status writes require connectivity. Beneficiary read-only offline cache is a stretch goal.

---

## Options

### Option A — Firestore real-time listener + status field on the intakes document *(Recommended)*

**Description.** Add `status`, `volunteerId`, and optional `cancellationReason` fields directly to the existing `intakes` Firestore collection. The Beneficiary client subscribes to `intakes/{id}` via `FirebaseFirestore.instance.doc(...).snapshots()`, exposed through a Riverpod `StreamProvider`. Volunteer actions (accept job, scan QR) are direct Firestore document writes from Volunteer screens, protected by Firestore Security Rules:

- Read: `resource.data.beneficiaryId == request.auth.uid || request.auth.token.role == 'volunteer'`
- Write `status` and `volunteerId`: only `request.auth.token.role == 'volunteer'`
- Legal transition guard in rules: current `status` must be `pending` for an accept write, `dispatched` for a collected write.

The QR scan delivers the Beneficiary's intake ID (embedded in the QR code); the Volunteer's client resolves this to the correct `intakes/{id}` document and performs the `dispatched → collected` write.

**Pros:**

- Real-time delivery is native to Firestore — no polling, no additional infrastructure.
- The Flutter SDK's `snapshots()` stream integrates directly with Riverpod `StreamProvider`, keeping the Presentation layer thin.
- Firestore Security Rules are the single enforcement point for RBAC — no custom server code needed.
- Aligns with the accepted Firebase stack (ADR-0004).
- Lowest overall effort: schema change is additive (new fields on an existing document), no new collections.
- Fully automated — no staff action is required at any point.

**Cons:**

- State machine rules are enforced in Firestore Security Rules rather than authoritative server logic. A compromised client with a valid volunteer token could attempt an illegal transition; the rules must be written to explicitly check the current status before allowing a write.
- No server-side audit trail of who changed status and when (unless a separate log document is written — out of scope for this proposal).

**Effort:** Small–medium. Additive schema change, new repository methods, one `StreamProvider`, two new screens (Beneficiary status detail, Volunteer queue + QR scanner).

**Satisfies hard constraints:** Yes — Firestore `snapshots()` delivers real-time updates; Security Rules enforce role-based read/write.

---

### Option B — Polling from a REST endpoint

**Description.** A backend HTTP endpoint returns the current status when queried. The client uses a Riverpod `AsyncNotifier` with a `Timer` to re-fetch every N seconds. Volunteer actions POST to the endpoint.

**Pros:**
- Server validates state machine transitions.
- RBAC enforced server-side.

**Cons:**
- Does not satisfy the real-time hard constraint — polling latency (10–30 s) is unacceptable for a Beneficiary waiting at the pickup point.
- Requires introducing a backend server component that does not currently exist.
- Higher battery and network usage than a persistent Firestore listener.

**Effort:** Large. New backend service, REST client, `AsyncNotifier` with timer, server deployment.

**Satisfies hard constraints:** No for real-time.

---

### Option C — Cloud Functions + Firestore real-time listener

**Description.** Volunteer status writes go through a Firebase Cloud Function (HTTPS callable) that validates the caller's role and enforces state machine rules before writing to Firestore. Beneficiary read path is identical to Option A.

**Pros:**
- State machine enforced in authoritative server-side code.
- RBAC enforced in the function's `context.auth.token`.

**Cons:**
- Introduces Cloud Functions as a new dependency not currently in the stack.
- Cold-start latency on every Volunteer action (first write after idle: 1–3 s).
- More moving parts to debug: function logs, Firestore writes, and listener must all be traced together.
- Disproportionate complexity for a five-state, four-transition machine.

**Effort:** Large. New `functions/` package, Cloud Functions deploy pipeline, callable function client in the Data layer.

**Satisfies hard constraints:** Yes.

---

## Recommendation

**Recommended: Option A — Firestore real-time listener + status field.**

Option A directly satisfies both hard constraints — real-time delivery via Firestore `snapshots()` and role-gated access via Firestore Security Rules — at the lowest effort and complexity cost. It requires no new infrastructure beyond additive schema changes to an existing collection, aligns entirely with the accepted Firebase stack (ADR-0004), and keeps the Domain layer clean (the repository interface returns a `Stream<IntakeRequest>` with no Firestore types leaking through).

Critically, Option A supports the fully automated marketplace model: the `pending → dispatched` and `dispatched → collected` transitions are triggered by Volunteer in-app actions with no staff intermediary. The Firestore Security Rules can encode legal-transition guards (`only allow write if resource.data.status == 'pending'` for an accept, `'dispatched'` for a collected write) explicitly.

The principal weakness — that state machine rules are in Security Rules rather than server logic — is acceptable for the current project scope. The rules are simple (four states, four legal transitions), the Volunteer role is a trusted registered actor, and the transition guards can be written inline. If the machine grows in complexity, migrating the write path to Cloud Functions (Option C) is a bounded, incremental change: the read path and Domain layer remain identical.

---

## Open Questions

1. **Volunteer visibility scope.** Should all Volunteers see all `pending` intake requests, or only requests geographically close to them or matching their registered distribution point? The answer affects the Firestore query and Security Rules on the volunteer queue screen.

2. **QR code format.** The Beneficiary's QR code must encode enough information for the Volunteer's scanner to identify the correct `intakes/{id}` document. Should the QR encode the raw document ID, or a one-time token that resolves server-side? A raw document ID is simpler but exposes the Firestore path; a token is safer but requires a Cloud Function or lookup mechanism.

3. **Volunteer cancellation flow.** If a Volunteer accepts a request (`dispatched`) but cannot complete the delivery, can they release it back to `pending` so another Volunteer can accept? Or is `dispatched → cancelled` the only allowed exit from `dispatched`? The first option improves resilience but complicates the queue UX.

4. **Beneficiary cancellation.** Can a Beneficiary cancel their own `pending` request before a Volunteer accepts? If yes, the Beneficiary must be allowed to write `status: cancelled` on their own document — a Security Rules exception to the general rule that Beneficiaries cannot mutate `status`.

5. **Intake collection identity.** Where do intake request documents currently live in Firestore — is there an existing `intakes` collection with established fields, or does this feature create it? If it already exists, the schema change must be kept additive.

---

## Acceptance Criteria

**Data model**

- The `IntakeRequest` domain entity has a `status` field typed as an enum: `pending`, `dispatched`, `collected`, `cancelled`.
- The `IntakeRequest` domain entity has a `volunteerId` field of type `String?` (null until a Volunteer accepts).
- The `IntakeRequest` domain entity has an optional `cancellationReason` field of type `String?`.
- `IntakeRequest` contains zero Flutter or Firebase imports.
- The `IntakeRequestModel` (Data layer) serialises `status` as a string to Firestore and deserialises it back without data loss.

**Automated transitions — Volunteer**

- Tapping "Accept Job" on the Volunteer queue screen writes `status: dispatched` and `volunteerId: <uid>` atomically; the transition is only allowed if the current status is `pending`.
- Scanning the Beneficiary's QR code on the Volunteer delivery screen writes `status: collected`; the transition is only allowed if the current status is `dispatched` and `volunteerId == request.auth.uid`.
- No staff action is required at any point in the lifecycle.

**Real-time updates — Beneficiary**

- A Beneficiary opening their intake detail screen subscribes to a live `Stream<IntakeRequest>` via a Riverpod `StreamProvider`.
- When a Volunteer accepts or delivers the request, the Beneficiary's screen reflects the new status within three seconds on a stable network connection, without any manual refresh.
- Cancelling the subscription (navigating away) does not leave an orphaned Firestore listener.

**Role-based visibility**

- Firestore Security Rules permit a Beneficiary to read only their own intake documents (`resource.data.beneficiaryId == request.auth.uid`).
- Firestore Security Rules permit a Volunteer (`role == 'volunteer'`) to read `pending` requests and their own accepted requests (`resource.data.volunteerId == request.auth.uid`).
- Firestore Security Rules permit a Volunteer to write `status` and `volunteerId` only for legal transitions.
- A Beneficiary attempting to write `status` (other than `cancelled` on their own `pending` document) receives a permission-denied error.
- A Volunteer attempting an illegal transition receives a permission-denied error and does not mutate the document.

**State machine**

- Legal transitions: `pending → dispatched` (Volunteer accepts), `dispatched → collected` (Volunteer QR scan), `pending → cancelled` (Beneficiary or system), `dispatched → cancelled` (Volunteer releases or system).
- All other transitions are rejected by Firestore Security Rules.
- Attempting an illegal transition from the Volunteer UI displays a user-facing error and does not mutate the Firestore document.

**Beneficiary UI**

- The Beneficiary intake status screen displays the current status as a labelled step indicator: Submitted → Volunteer Dispatched → Delivered.
- When status is `cancelled`, the `cancellationReason` string (if present) is displayed below the status indicator.
- All status labels use `Theme.of(context).textTheme` — no hardcoded text styles.

**Volunteer UI**

- The Volunteer queue screen lists all `pending` intake requests using `ListView.builder`.
- The Volunteer's "My Deliveries" section lists their own `dispatched` requests.
- Tapping a request opens a detail view with an "Accept Job" button (for `pending`) or a "Scan QR" button (for `dispatched`).
- A successful status write shows a confirmation snackbar; a failed write shows an error snackbar and leaves the status unchanged in the UI.

**Architecture constraints**

- The repository interface `IntakeRepository` is defined in the Domain layer and returns `Stream<IntakeRequest>` and `Future<void>` — no Firestore types in the interface.
- The Firestore implementation `FirestoreIntakeRepository` lives in the Data layer and is the only file that imports `cloud_firestore`.
- Presentation providers depend only on the Domain use cases — never on `FirestoreIntakeRepository` directly.
- Every new screen has a corresponding widget test.
