---
title: "0005: Beneficiary Impact Screen"
description: "Add a dedicated Impact screen that surfaces cumulative food-aid metrics to beneficiaries — meals received, kilograms rescued, and CO₂e prevented — backed by a new beneficiary-scoped impactMetrics document kept in sync by the existing onDeliveryComplete Cloud Function."
---

# PROP-0005: Beneficiary Impact Screen

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-02
**Spec:** [SPEC-0005](../tech-specs/0005-beneficiary-impact-screen.md)
**Approved by:** ALORA

---

## Problem

Beneficiaries who use SaveAMeal — shelter coordinators such as Sister Maria in Klong Toey, who feeds ~60 children nightly — currently have no way to see the cumulative impact of food aid they have received through the platform. There is no screen, widget, or data surface that answers the questions: "How many meals has SaveAMeal delivered to us this month? How many kilograms of food have we received? How many deliveries have we had?"

This gap matters for three reasons:

1. **Beneficiary motivation and trust.** A user who cannot see any evidence that the platform has helped them over time has no reinforcement mechanism. For a low-tech user on a shared tablet, the absence of a running total feels the same as no data existing at all.

2. **Institutional reporting.** Beneficiary organisations (shelters, orphanages, community kitchens) may need to report food-intake figures to funders or government bodies. The platform produces this data as a by-product of every delivery but currently exposes none of it to the beneficiary side.

3. **The backend data already exists — partially.** The `onDeliveryComplete` Cloud Function (introduced in the `feat/beneficiary-impact` branch) already fires on the `* → delivered` batch status transition. It calls `computeTotals(items)` — which returns `totalKg`, `totalMeals`, and `totalCo2e` — and writes those increments atomically to `impactMetrics/{donorId}` and `impactMetrics/global`. The computation logic and the Firestore write pattern are already proven. However, **the function does not write a beneficiary-scoped document**. There is no `impactMetrics/{beneficiaryId}` entry, no delivery-count field, and no per-beneficiary aggregation of any kind. The donor dashboard (PROP-0002) is already fed from this collection; the beneficiary side is not.

The gap is therefore both a product gap (no UI) and a backend gap (no beneficiary-scoped data). Any solution must close both.

---

## Goals

- A beneficiary opening the app can see their cumulative impact metrics: total meals received, total kilograms of food, total CO₂e prevented, and total number of completed deliveries.
- Metrics update automatically after each delivery completes — the beneficiary does not need to pull-to-refresh or navigate away and back.
- The impact data is accurate and authoritative: it is not computed by the client from raw delivery documents, but maintained by a server-side process that runs atomically.
- The feature follows Clean Architecture: the Domain entity and repository interface are pure Dart; the Firestore implementation is isolated in the Data layer; the Presentation layer depends only on Domain use cases.
- Firestore Security Rules permit a beneficiary to read only their own impact document.
- The screen degrades gracefully when no deliveries have been completed yet (empty/zero state).
- All text styles, colors, and spacing use the app's theme system — no hardcoded values.

---

## Non-goals

- Impact metrics for donors or drivers — those are separate features (donor dashboard already exists in PROP-0002).
- A global or platform-wide impact leaderboard visible to beneficiaries.
- Per-delivery breakdown or itemised delivery history list — that is a separate history feature. This proposal covers only aggregate counters.
- Offline mutation or offline-first sync — metrics are read-only from the beneficiary client's perspective; a cached last-known value for offline display is a stretch goal.
- Filtering by date range or category — MVP shows all-time totals only.
- Push notification when a new delivery updates the metrics — FCM is already handled by `onDeliveryComplete`; this proposal covers only the data and screen, not new notification types.
- Editing or correcting delivery data from the beneficiary side.

---

## Options

### Option A — Extend `onDeliveryComplete` to write beneficiary metrics, stream pre-aggregated document *(Recommended)*

**Description.** The `onDeliveryComplete` Cloud Function is amended to also write atomic `FieldValue.increment()` updates to `impactMetrics/{beneficiaryId}`, mirroring what it already does for the donor. The Flutter client streams this single Firestore document via a Riverpod `StreamProvider`, rendering the four counters (meals, kg, CO₂e, delivery count) in real-time on a dedicated Impact screen.

The Firestore Security Rules already include a rule for `impactMetrics/{docId}` that permits reads where `docId == uid()` — beneficiary reads of their own impact document are therefore already permitted without any rule change.

The donor dashboard (PROP-0002) uses the same pattern: it reads `impactMetrics/{donorId}` via a stream. The beneficiary impact screen is structurally identical, consuming `impactMetrics/{beneficiaryId}` instead.

**Pros:**
- Reuses the proven `computeTotals()` function and the existing `FieldValue.increment()` write pattern from `onDeliveryComplete` — minimal new backend code, high confidence in correctness.
- Aligns exactly with how the donor dashboard works, giving the team a concrete, working reference implementation.
- Single Firestore document read per session — lowest possible read cost (one document, one listener).
- Real-time: the Firestore listener fires the moment the Cloud Function writes, so the beneficiary screen updates without any user action.
- No new Cloud Function, no new Firestore collection — additive changes only.
- The Firestore Security Rules already cover this read path; no rule change required.
- Offline story: Firestore's local cache means the last-known values are shown even without connectivity. Writes happen server-side so there is no offline mutation concern.

**Cons:**
- Requires amending the `onDeliveryComplete` Cloud Function — a backend change that must be coordinated with whoever owns the functions deployment.
- Historical deliveries that completed before this change is deployed will not be counted. The beneficiary impact counters will start from zero at launch, not back-filled. A one-time migration script could address this but is out of scope for the MVP.
- The `impactMetrics` document does not store individual delivery timestamps, so there is no way to add per-delivery detail later without augmenting the schema.

**Effort:** Small. One function amendment (three lines), one new Firestore read in the Data layer, one domain entity, one repository interface method, one `StreamProvider`, one new screen.

---

### Option B — Client-side aggregation over the `batches` collection

**Description.** The client queries the `batches` collection for all documents where `beneficiaryId == currentUser.uid && status == 'delivered'` (or `'closed'`), loads them all, and runs `computeTotals()` locally to derive the metrics. No backend change is required.

**Pros:**
- Zero backend changes — works with the existing `batches` collection as-is.
- The client controls the aggregation logic, making it easy to add new breakdowns (by date range, by food category) without a Cloud Function change.
- No dependency on the `impactMetrics` collection or the `onDeliveryComplete` function.

**Cons:**
- Firestore read cost scales linearly with the number of completed deliveries per beneficiary. A shelter with 200 completed deliveries pays 200 document reads every time the screen is opened. At scale this is expensive and slow.
- Requires a composite Firestore index (`beneficiaryId` + `status`) on the `batches` collection. The current Security Rules allow beneficiaries to read only batches where `beneficiaryId == uid()`, but the existing rule reads from the `batches` collection without a sub-collection restriction — this needs verification.
- Real-time updates require a `snapshots()` listener on a collection query, not a single document — the listener fires and re-aggregates the full result set on every batch update by any party, which is noisy and expensive.
- The `computeTotals()` logic lives in the TypeScript functions package today; it would need to be re-implemented in Dart, creating a risk of divergence.
- Offline story is poor: the full batch collection query may not be cached locally if the user has not visited the screen since the cache was populated.

**Effort:** Small–Medium. No backend changes, but requires a composite index, a collection-level `StreamProvider` with client-side aggregation, careful read-cost analysis, and a Dart re-implementation of `computeTotals`.

---

### Option C — HTTPS-callable Cloud Function returning a computed impact summary

**Description.** A new HTTPS-callable Cloud Function accepts the authenticated beneficiary's UID (from `context.auth`), queries the `batches` collection for their completed deliveries, runs `computeTotals()`, and returns a structured JSON summary. The Flutter client calls this function on screen load and on a manual refresh action, rendering the result via a Riverpod `FutureProvider`.

**Pros:**
- Server-side computation is authoritative and re-usable — the same endpoint could power a future admin dashboard or export feature.
- No new Firestore collection or document schema needed — the function reads raw batch data.
- Clean separation: the function owns the aggregation logic in one place.

**Cons:**
- No real-time updates — the beneficiary must manually refresh to see new data. This is a significant UX regression compared to the live-updating donor dashboard and the real-time delivery tracking already in the app.
- Cold-start latency (1–3 seconds on first call after idle) introduces a visible loading spinner every time the screen is opened.
- Introduces a new Cloud Function with its own deployment, versioning, and cold-start surface. Given the project's 10-day delivery window (WBS), adding a net-new function for a read-only UI feature is disproportionate.
- Per-call Firestore reads inside the function (scanning the full batch collection for one beneficiary) are unbounded and grow with history, replicating the cost problem of Option B at the server level.
- Offline story is the worst of all options: the function is unreachable without connectivity and the `FutureProvider` will show an error state.

**Effort:** Medium. New Cloud Function, callable client wrapper in the Data layer, `FutureProvider`, pull-to-refresh UX, error handling.

---

### Option D — Embedded impact summary widget in an existing beneficiary screen

**Description.** Rather than a dedicated Impact screen, a compact impact summary widget (showing total meals and total kg) is embedded directly in the existing Beneficiary Dashboard or Profile screen. The data source is the same `impactMetrics/{beneficiaryId}` document from Option A, or alternatively a small subset of the `batches` query from Option B. No new route is added.

**Pros:**
- Lower navigation complexity — the beneficiary sees impact figures immediately on their home screen without finding a separate section.
- Reduces the scope of the screen change to a widget addition rather than a new route, screen, and GoRouter entry.
- For a low-tech user (Sister Maria's persona), fewer taps is better.

**Cons:**
- Screen real estate on the Beneficiary Dashboard is already occupied by the status toggle (C1), the incoming delivery banner (C2), and the tracking map link (C3). Adding a metrics widget competes with operational content.
- Limits the metrics surface to whatever fits in an inline card — expanding to a richer impact view later requires extracting into a dedicated screen anyway, incurring the reversal cost of a navigation change.
- If the team later wants to add a delivery history list (a logical complement to impact totals), there is nowhere to put it without a dedicated screen.
- Does not give the feature its own navigable URL, which matters for deep-linking from FCM notifications (e.g., "You've received your 10th delivery — view your impact").

**Effort:** Small. Fewer files than Option A, but the architectural ceiling is lower.

---

## Recommendation

**Recommended: Option A — extend `onDeliveryComplete` + stream pre-aggregated document.**

Option A is the correct choice because it produces a real-time, low-cost, low-complexity solution that is already half-built. The computation logic (`computeTotals`), the Firestore write pattern (`FieldValue.increment`), the collection (`impactMetrics`), and the Security Rules are all already in place for the donor side. The backend delta is three lines of Cloud Function code. The Flutter delta is one stream, one entity, one screen — the same pattern used successfully in the donor dashboard.

Option B's client-side aggregation solves the backend-change dependency at the cost of an unbounded Firestore read on every screen open, a Dart re-implementation of server logic, and a noisy collection listener. These costs compound as a beneficiary accumulates history. Option C is real-time-incapable and adds cold-start latency for a read-only feature, which is a poor trade for a screen that should update automatically. Option D constrains the feature's future surface area — the metrics are the most natural anchor for a delivery history view, and embedding them in an already-crowded dashboard forecloses that path.

The only material weakness of Option A is the lack of historical back-fill: deliveries that completed before the feature ships will not appear in the counters. This is an acceptable product decision for an MVP that will launch with a small pilot dataset. The reversal cost of adding a back-fill script later is low — it is a one-time Firestore admin operation against the existing `batches` collection.

---

## Open Questions

1. **Back-fill decision.** The impact counters will start at zero for all existing beneficiaries on launch day because `onDeliveryComplete` will only begin writing beneficiary metrics once the amended function is deployed. Is a back-fill migration (scanning completed batches and seeding `impactMetrics/{beneficiaryId}`) required for the demo, or is a zero-start acceptable given the pilot dataset?

2. **Metric set for MVP.** The proposal assumes four counters: total meals, total kilograms, total CO₂e prevented, and total completed deliveries. Should the screen also show a "most recent delivery" timestamp? The `impactMetrics` document schema needs to be agreed before the Cloud Function amendment is written — adding a `lastDeliveryAt` timestamp field requires a one-line change to the function but must be in the spec before implementation begins.

3. **Empty / zero state UX.** What should a new beneficiary see before any deliveries have been completed? Options include: a zero-filled metrics display, a placeholder card ("Your first delivery is on its way"), or hiding the screen entirely until the first delivery. The product team must decide — the spec writer needs a clear answer to define the acceptance criteria.

4. **Delivery history sub-collection.** Option A covers aggregate counters only. If a delivery history list (one row per completed delivery, with date, kg, and driver name) is wanted in the same or a follow-on sprint, the `batches` collection can serve as the source. However, the screen architecture should be decided now: a dedicated Impact screen (this proposal) can host a history list naturally as a lower section, while an embedded widget (Option D) cannot. Confirm the screen is the right surface before the spec locks the route structure.

5. **`onDeliveryComplete` ownership.** The function currently lives in `functions/src/onDeliveryComplete.ts`. Who is responsible for deploying the amended version? The amendment is small, but the deployment step must be assigned before the flutter-engineer begins the Flutter side — the screen is unusable until the function writes beneficiary data.

---

## Acceptance Criteria

**Backend**

- `onDeliveryComplete` writes atomic `FieldValue.increment()` updates for `totalKg`, `totalMeals`, `totalCo2e`, and `totalDeliveries` to `impactMetrics/{beneficiaryId}` whenever a batch transitions to `delivered` and `beneficiaryId` is present on the batch document.
- The write uses `set(..., { merge: true })` so the document is created on first delivery and incremented on subsequent ones — identical to the existing donor write pattern.
- If `beneficiaryId` is absent on the batch, the beneficiary write is skipped with a warning log, and the existing donor and global writes proceed normally.

**Data model**

- A `BeneficiaryImpact` domain entity exists in the Domain layer with fields: `totalKg` (double), `totalMeals` (double), `totalCo2e` (double), `totalDeliveries` (int). It contains zero Flutter or Firebase imports.
- The corresponding Data-layer model serialises all fields from the `impactMetrics/{beneficiaryId}` Firestore document and deserialises them without data loss, defaulting missing fields to zero.

**Repository and use case**

- The domain repository interface exposes a method that returns a `Stream<BeneficiaryImpact>` for the current beneficiary's UID.
- The Firestore implementation of this method streams the `impactMetrics/{beneficiaryId}` document and maps it to the domain entity. It is the only file in the feature that imports a Firebase package.
- A use case wraps the repository call and is the only dependency the Presentation layer takes from Domain.

**Presentation**

- A dedicated Impact screen exists, reachable from the Beneficiary Dashboard via navigation.
- The screen displays four labelled metric tiles: meals received, kilograms rescued, CO₂e prevented, and deliveries completed.
- Metric values update in real-time via a Riverpod `StreamProvider` — no pull-to-refresh is required.
- When the stream emits a document with all-zero values or no document has been written yet, the screen shows a clearly labelled zero or empty state — it does not crash or show loading indefinitely.
- All text styles, colors, and spacing use `Theme.of(context).textTheme`, `Theme.of(context).colorScheme` (`cs`), and `Theme.of(context).extension<AppColors>()!` (`ac`) — no hardcoded values.
- The screen widget has a corresponding widget test.

**Security**

- Firestore Security Rules continue to permit a beneficiary to read `impactMetrics/{docId}` only where `docId == uid()`. No rule change is required; this is confirmed by reading the existing rules.
- A beneficiary attempting to write to `impactMetrics/{uid}` receives a permission-denied error (existing rule: `allow write: if false`).

**Architecture**

- The Presentation layer depends only on the Domain use case — never on the Firestore repository implementation directly.
- The Domain entity and repository interface have zero Flutter or Firebase imports.
- `flutter analyze` passes with no new warnings introduced by this feature.
