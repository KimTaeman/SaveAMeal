---
title: "0006: Donor dashboard data strategy — Firestore real-time listeners with Hive write-through cache"
description: "Establishes how the donor dashboard satisfies the dual constraints of real-time batch status updates and offline data availability."
---

# 0006 — Donor Dashboard Data Strategy: Firestore listeners + Hive write-through cache

**Status:** PROPOSED
**Author:** Kim Taeman (architect)
**Date:** 2026-05-23

## Problem

The donor dashboard must satisfy two constraints that pull in opposite directions: batch status changes must surface live (within five seconds, no manual refresh), and the last-known dashboard state must render without a network connection. Firestore's built-in offline persistence alone cannot guarantee cold-start data availability across reinstalls or cache eviction, and polling cannot satisfy the real-time constraint at a reasonable interval. A deliberate data strategy must be chosen before the Domain and Data layers are implemented.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Pure Firestore real-time listeners (no Hive) | Zero cache-write code; SDK manages offline reads automatically | Cache not guaranteed on cold start after reinstall; opaque eviction policy; Web requires extra persistence init; violates ADR-0003 consistency |
| 2 | Hive-primary store with periodic Firestore polling | Predictable network usage; no stream lifecycle management | Status changes delayed by poll interval (breaks real-time constraint); background execution required on iOS/Android; does not work on Web |
| 3 | Firestore real-time listeners + Hive write-through cache | Satisfies both constraints; consistent with ADR-0003; Hive cache is explicit and controllable; works on all three platforms | Two write paths increase repository complexity; cache invalidation needed on schema changes |

## Decision

**Chosen:** Option 3 — Firestore real-time listeners with Hive write-through cache

The `DonorRepository` interface exposes `Stream<List<Batch>>` and `Stream<DonorMetrics>` — the implementation subscribes to Firestore `snapshots()` for live data and writes each emission into the corresponding Hive boxes (`batches`, `donorMetrics`). On startup, the repository emits from Hive immediately, then replaces with Firestore data once the first snapshot arrives. This satisfies real-time updates (Firestore listener) and offline reads (Hive seed) with a single, cohesive repository implementation. The approach is consistent with the caching strategy established in ADR-0003.

## Reversal Cost

Medium — switching to pure Firestore persistence (Option 1) requires deleting the Hive write-through logic in `DonorRepositoryImpl` and removing the `batches`/`donorMetrics` Hive boxes and their `TypeAdapter`s. The Domain layer (interfaces, entities, use cases) and the Presentation layer (providers, screens) are unaffected because they depend only on the repository interface, not its implementation.

## Consequences

Easier: offline-first rendering with a predictable, inspectable cache; consistent architecture across all feature repositories; Hive boxes can be pre-populated in integration tests for deterministic offline scenarios.

Harder: `DonorRepositoryImpl` must manage two write destinations per emission; Hive `TypeAdapter`s for `Batch` and `DonorMetrics` must be generated and kept in sync with domain entity changes; any field rename on `Batch` or `DonorMetrics` requires regenerating adapters and clearing existing boxes.
