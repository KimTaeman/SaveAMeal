---
title: '0002: Donor Dashboard — real-time batch tracking and impact metrics'
description: "Design the donor's post-login home screen: live batch status updates, impact metrics summary, and offline-capable cached data."
---

# PROP-0002: Donor Dashboard — real-time batch tracking and impact metrics

**Status:** ACCEPTED
**Author:** Kim Taeman
**Date:** 2026-05-23
**Spec:** tech-specs/0002-donor-dashboard.md
**Approved by:** NADI

---

## Problem

After authentication, a donor is routed to `DonorDashboardScreen`, which today renders a single `Text('TODO: DonorDashboardScreen')` placeholder. The donor has no actionable home page: they cannot see the live status of batches they have logged, they receive no confirmation when a driver claims or picks up their food, and they have no visibility into the cumulative social impact their donations have generated.

This matters at three levels:

1. **User trust.** Donors who log a batch and see no feedback assume the system dropped their data. Without a "claimed / picked up" signal, repeat usage and donor retention are at risk.
2. **Lifecycle blindness.** The `Batch` entity has a five-step status lifecycle (`open → claimed → pickedUp → delivered → closed`), but nothing surfaces these transitions to the donor in real time.
3. **Motivational gap.** The `impactMetrics` Firestore collection is being written by the `onDeliveryComplete` Cloud Function, but the aggregated totals (weight donated, portions served, deliveries completed) are never surfaced to the donor who generated them.

The technical gaps that must be closed before any UI work begins:

- `DonorRepository` is an empty stub — no method signatures are defined.
- `CreateBatchUsecase` and `GetDonorMetricsUsecase` have no `call` method bodies.
- `donor_provider.dart` is a blank file — no Riverpod providers exist.
- `DonorRemoteDatasource` has no contract methods and no Firestore wiring.

A donor who closes the app mid-delivery and reopens it on a low-connectivity connection must still see their last-known batch state and metrics — Hive caching is a hard constraint per the project architecture (ADR-0003).

---

## Proposed Solution

**Hybrid: Firestore real-time listeners as the live source, Hive as the offline fallback.**

The `DonorRepository` interface exposes two streams and one write operation in the Domain layer:

- `Stream<List<Batch>> watchActiveBatches(String donorId)` — emits whenever any of the donor's non-closed batches change status.
- `Stream<DonorMetrics> watchMetrics(String donorId)` — emits whenever the `impactMetrics/{donorId}` document is updated by the Cloud Function.
- `Future<void> createBatch(Batch batch)` — writes a new batch document (called by `CreateBatchUsecase`).

The Data layer implements these against Firestore's `snapshots()` API. On each emission, the repository also writes through to Hive (a `batches` box and a `metrics` box). On startup, the repository seeds both streams from Hive first, then replaces with the live Firestore snapshot once the listener fires — this provides instant UI rendering with no spinner on reconnect.

In the Presentation layer, two `@riverpod` `StreamProvider`s expose the domain streams. `DonorDashboardScreen` consumes both providers and renders:

1. An impact metrics card (weight, portions, deliveries) at the top.
2. A `ListView.builder` of active batch cards, each displaying the current `BatchStatus` and surfacing a "View QR" action for `open` batches.
3. A FAB that navigates to `LogBatchScreen`.

Firestore's built-in offline persistence (enabled by default in the FlutterFire SDK) handles in-flight writes when the device goes offline. Hive handles the read-side cache so the UI renders even when Firestore's internal cache is cold (first launch after reinstall or cache eviction).

---

## Alternatives Considered

### A — Pure Firestore real-time snapshots with no Hive layer

Use Firestore's built-in offline persistence exclusively. The `StreamProvider`s call `snapshots()` and Firestore's SDK caches documents automatically on device.

**Upside:** Zero cache-write code in the repository. No `TypeAdapter` generation. Simplest implementation path — the SDK handles all offline reads transparently.

**Downside:** Firestore's internal cache is not guaranteed to be populated on first cold launch after reinstall or cache eviction. The cache is also opaque — there is no way to inspect, pre-populate, or control eviction policy from Dart code. This makes it impossible to guarantee data availability for offline scenarios that start before any Firestore connection has been established. Firestore's offline support also does not work on Web by default (requires `enableIndexedDbPersistence()` with separate error handling). Effort estimate: low.

**Rejected:** Violates the hard offline constraint. The Hive layer (ADR-0003) is already a settled architectural decision; removing it here would create an inconsistency with the rest of the app's caching strategy.

### B — Cached-first with Hive as the primary store and periodic Firestore polling

Hive is the sole data source for the UI. A background `Timer` or `WorkManager` job polls Firestore on a configurable interval (e.g., every 30 seconds), writes results to Hive, and the Riverpod provider reads from Hive. No Firestore stream listeners in the domain flow.

**Upside:** Predictable network usage. Works identically on all platforms. No stream lifecycle management. Battery-friendly for donors who check the app infrequently.

**Downside:** Status transitions are delayed by up to one polling interval. A batch moving from `open` to `claimed` is not visible to the donor for up to 30 seconds — this is a poor experience for the "magic moment" when a driver accepts the food. Polling also requires a background execution context, which adds complexity (`WorkManager` on Android, `BGTaskScheduler` on iOS) and does not work on Web. Effort estimate: high (background execution plumbing) with worse UX outcome.

**Rejected:** The real-time constraint is explicit. Polling cannot satisfy it without an interval short enough to defeat the battery/network savings that make polling attractive in the first place.

### C — Hybrid: Firestore real-time listeners + Hive write-through cache (recommended)

As described in the Proposed Solution. Firestore `snapshots()` drives live updates; the repository writes each emission to Hive; on startup, Hive seeds the initial UI render before the first Firestore snapshot arrives.

**Upside:** Satisfies both constraints (real-time and offline). Consistent with ADR-0003. Hive gives explicit, inspectable, controllable cache state. Works identically on Android, iOS, and Web (Hive uses IndexedDB on Web). No background execution required — the Firestore listener is active only while the app is foregrounded, and Hive serves reads when the listener is absent.

**Downside:** Two write paths (Firestore and Hive) must stay in sync — the repository implementation is more complex than Option A. Cache invalidation on schema changes requires clearing Hive boxes and regenerating `TypeAdapter`s. Effort estimate: medium.

**Chosen:** This is the recommended approach.

---

## Open Questions

1. **Metrics document shape.** The `impactMetrics/{donorId}` Firestore document is written by the `onDeliveryComplete` Cloud Function, but its field names are not yet defined in the codebase. What are the exact field names (`totalWeightKg`? `portionsServed`? `deliveriesCompleted``)? This must be settled before the `DonorMetrics`domain entity can be defined and the`TypeAdapter` generated.

2. **Active vs. historical batch scope.** Should `watchActiveBatches` return only batches with `status != closed`, or should the dashboard also show a paginated history of closed batches? Infinite scroll or a separate "History" tab would have different Firestore query and Hive storage implications.

3. **Batch list ordering and Firestore index.** A compound Firestore query on `donorId == x AND status != closed ORDER BY createdAt DESC` requires a composite index. Has this been created in the Firebase console, or does it need to be added to `firestore.indexes.json`? The query shape must be confirmed before the datasource is implemented.

4. **Metrics update latency.** The `onDeliveryComplete` Cloud Function runs on the `batches/{batchId}` `onUpdate` trigger. What is the expected cold-start latency for this function? If it is consistently above five seconds, the donor may see the batch move to `delivered` in their list before the metrics card reflects the new totals — a visible inconsistency that may need a loading shimmer on the metrics card.

5. **Empty state.** What should the dashboard display for a donor who has never logged a batch? A call-to-action directing them to `LogBatchScreen`, or a different onboarding surface? This affects whether the dashboard needs a `hasNoBatches` state distinct from a loading state.

---

## Acceptance Criteria

The following criteria are written to feed directly into the tech spec and QA test matrix.

**Real-time updates**

- When a driver claims a batch, the batch card on the donor dashboard transitions from `open` to `claimed` within five seconds, without the donor manually refreshing.
- When a batch reaches `delivered`, the impact metrics card increments within ten seconds of the Cloud Function completing.

**Offline / cached data**

- With network connectivity disabled, the dashboard renders the last-known list of batches and the last-known metrics from Hive cache within two seconds of navigation to the screen.
- No error state or empty screen is shown when the device is offline and Hive has previously cached data.
- When connectivity is restored, the dashboard silently re-syncs with Firestore without requiring user action.

**Impact metrics summary**

- The metrics card displays three values: total weight donated (kg), total portions served, and total deliveries completed, sourced from `impactMetrics/{donorId}`.
- For a donor with no completed deliveries, the metrics card displays zeros, not a missing/error state.

**Batch lifecycle visibility**

- Each batch card displays the current `BatchStatus` label (open, claimed, picked up, delivered, closed).
- Batches in `open` status display a "View QR" action that navigates to `BatchQrScreen`.

**Architecture constraints**

- `DonorRepository` interface, `Batch` entity, and `DonorMetrics` entity contain zero Flutter or Firebase imports.
- The Presentation layer accesses batch and metrics data exclusively through Riverpod `StreamProvider`s — no direct Firestore or Hive calls in widgets or screens.
- All batch data passed through `ListView.builder` — no unbounded `ListView`.

**Navigation**

- `DonorDashboardScreen` provides a FAB that navigates to `LogBatchScreen`.
- `LogBatchScreen` on successful submission navigates back to the dashboard and the new batch appears in the list within five seconds.
