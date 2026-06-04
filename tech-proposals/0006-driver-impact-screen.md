---
title: "0006: Driver Impact Screen"
description: "Add per-driver impact accumulation in Firestore and build the DriverImpactScreen with leaderboard support."
---

# PROP-0006: Driver Impact Screen

**Status:** PROPOSED
**Author:** chotiya
**Date:** 2026-06-03
**Spec:** (pending approval)
**Approved by:** (fill in when accepted)

---

## Problem

The driver bottom navigation declares an Impact tab (index 1), but tapping it is a no-op. The `/driver/impact` route is not registered in `router.dart` and `onDestinationSelected` never handles that index.

The root cause goes deeper than a missing route. There is no backend data to display:

- `onDeliveryComplete.ts` writes `impactMetrics/{donorId}` on every delivery but makes no equivalent write for the driver, even though `after['driverId']` is available on the batch document.
- `UserModel` carries a `points` field (`@Default(0) int points`) but no Cloud Function ever increments it for drivers.
- No `leaderboard` collection exists anywhere in the codebase.
- `FirestoreService` exposes `watchDonorMetrics(donorId)` but has no `watchDriverMetrics(driverId)` counterpart.

The result is that drivers have no visibility into their personal contribution (kg rescued, meals delivered, CO2e avoided) and no gamification incentive, despite the UI chrome implying otherwise.

A secondary data-quality issue: `computeTotals` in `computations.ts` applies the same multiplier `2.5` to both `totalMeals` and `totalCo2e`, which are conceptually distinct quantities and should use different constants.

## Proposed Solution

The solution has four coordinated parts spanning the backend Cloud Function, the Firestore data model, the `FirestoreService` abstraction, and the Flutter feature.

### 1. Extend `onDeliveryComplete.ts`

On every delivery completion, in addition to the existing donor writes, also write:

- `impactMetrics/{driverId}` — `FieldValue.increment` on `totalKg`, `totalMeals`, `totalCo2e` (same computation as the donor path).
- `users/{driverId}.points` — `FieldValue.increment(10)` per delivery (value is a placeholder pending team confirmation — see Open Questions).
- `leaderboard/{driverId}` — `set` with merge on `{ points, displayName, totalDeliveries, updatedAt }`. `totalDeliveries` is incremented via `FieldValue.increment(1)`. This document is maintained as a flat, denormalised record for efficient top-N queries.

All three writes should be batched in a single Firestore batch commit so they are atomic.

### 2. Add `watchDriverMetrics(driverId)` to `FirestoreService`

Mirror `watchDonorMetrics` to stream the `impactMetrics/{driverId}` document. This keeps the service interface symmetric and allows the Flutter layer to react in real time.

### 3. Build the Flutter feature under Clean Architecture

```
features/driver/
  domain/
    entities/driver_impact.dart          ← pure Dart: totalDeliveries, totalKg, totalMeals, totalCO2e, points
    entities/leaderboard_entry.dart      ← pure Dart: rank, driverId, displayName, points, totalDeliveries
    repositories/driver_impact_repository.dart   ← abstract interface
    usecases/get_driver_impact_usecase.dart
    usecases/get_leaderboard_usecase.dart
  data/
    models/driver_impact_model.dart      ← Freezed + JSON; maps impactMetrics document
    models/leaderboard_entry_model.dart  ← Freezed + JSON; maps leaderboard document
    repositories/driver_impact_repository_impl.dart
  presentation/
    providers/driver_impact_provider.dart   ← @riverpod, streams driverImpactProvider
    providers/leaderboard_provider.dart     ← @riverpod, streams leaderboardProvider
    screens/driver_impact_screen.dart
    widgets/impact_stat_card.dart
    widgets/leaderboard_list.dart
```

`DriverImpact` entity fields: `totalDeliveries`, `totalKg`, `totalMeals`, `totalCO2e`, `points`.  
`LeaderboardEntry` entity fields: `rank` (derived client-side from list position), `driverId`, `displayName`, `points`, `totalDeliveries`.

### 4. Register the route and wire the bottom nav

Register `/driver/impact` in `router.dart` and handle index 1 in `onDestinationSelected` on the driver shell scaffold.

## Alternatives Considered

### A — Client-side aggregation

Query all batch documents where `driverId == uid` and `status == 'delivered'` in Flutter, then aggregate `totalKg`, `totalMeals`, and `totalCo2e` on the device. This mirrors the current `watchDonorMetrics` implementation.

**Rejected:** The donor approach already shows scalability concerns — a driver with hundreds of deliveries would read hundreds of documents on every app open. The collection grows unbounded over time. This approach also cannot support a leaderboard without reading all drivers' full delivery histories, which is not viable.

### B — Scheduled leaderboard Cloud Function

A Cloud Scheduler function runs on a cron (e.g., hourly or daily), queries `users` ordered by `points`, and writes a ranked `leaderboard` snapshot collection.

**Rejected:** Data is stale between runs, which reduces the motivational value of the leaderboard. The scheduled function adds operational complexity (monitoring, failure handling) that the delivery trigger approach does not. The delivery trigger already has all the information needed at the moment of the write, making a separate scheduled pass redundant.

### C — Composite index query on `users` collection for leaderboard

Query the `users` collection ordered by `points` descending with a filter on `role == driver`. No separate `leaderboard` collection is maintained.

**Rejected:** Requires a composite Firestore index. Reads full user documents (which may contain sensitive fields) purely for ranking. Does not scale efficiently past a few hundred drivers without pagination complexity. A dedicated `leaderboard` collection containing only public ranking fields is the established Firestore pattern for leaderboard use cases and keeps the query simple.

## Open Questions

1. **CO2e conversion factor:** `computations.ts` uses `totalKg * 2.5` for both `totalMeals` and `totalCo2e`. These represent different real-world quantities and must use different constants. What are the correct factors? This must be resolved before the backend write logic is finalised.

2. **Points value per delivery:** This proposal uses 10 points per delivery as a placeholder. What is the intended value, and should it vary by delivery size (e.g., proportional to `totalKg`)?

3. **Leaderboard time window:** Should the leaderboard be all-time only, or should it support time-windowed views (weekly, monthly)? An all-time design stores a single document per driver in `leaderboard/{driverId}`. Time-windowed views require either a subcollection per period (`leaderboard/{driverId}/windows/{YYYY-WW}`) or a separate top-level collection per window, which significantly changes the schema.

4. **Leaderboard display cap:** How many entries should be shown (top 10, top 50)? This determines the Firestore query `limit` and affects whether pagination is required.

5. **`displayName` source:** Does the driver's user document carry a `displayName` field, or must it be constructed by concatenating `firstName` + `lastName` at write time in the Cloud Function? The leaderboard document must store a pre-computed display string to avoid a join at read time.

## Acceptance Criteria

- Tapping the Impact tab in the driver bottom nav navigates to `DriverImpactScreen` without error.
- After a delivery is marked complete, `impactMetrics/{driverId}` is created or incremented within the Firestore transaction.
- After a delivery is marked complete, `users/{driverId}.points` is incremented by the agreed value.
- After a delivery is marked complete, `leaderboard/{driverId}` is created or updated with current `points`, `displayName`, `totalDeliveries`, and `updatedAt`.
- `DriverImpactScreen` displays `totalDeliveries`, `totalKg`, `totalMeals`, `totalCO2e`, and `points` sourced from `impactMetrics/{driverId}`.
- `DriverImpactScreen` displays a leaderboard ordered by `points` descending, limited to the agreed cap.
- `DriverImpact` and `LeaderboardEntry` domain entities import zero Flutter or backend packages.
- The domain repository interface is an abstract Dart class in `domain/repositories/`.
- All new Dart files pass `flutter analyze` with zero warnings.
- `DriverImpactScreen` has a widget test covering the loading, loaded, and error states.
