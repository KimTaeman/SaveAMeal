# 0012 — Separate `IntakeRequestDetail` entity for the batch detail view

**Status:** PROPOSED
**Author:** architect
**Date:** 2026-06-04

## Problem

`DeliveryDetailScreen` needs item-level batch data (`List<IntakeItem>`) that `IntakeRequest` does not carry. Two structural options exist: widen the shared `IntakeRequest` entity to carry the item list, or introduce a dedicated `IntakeRequestDetail` entity used only by the detail screen. The choice determines whether the list-view stream (used by the beneficiary dashboard) carries unnecessary allocation overhead on every Firestore snapshot, and whether list and detail read concerns remain decoupled in the domain.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Add `List<IntakeItem> items` to existing `IntakeRequest` | Fewer files; existing providers reusable; `WatchIncomingBatchUsecase` stub completes naturally | Every `watchActiveDeliveries` snapshot allocates and discards the item array; list and detail concerns share a mutable boundary; field additions for either concern widen a shared entity |
| 2 | New `IntakeRequestDetail` entity with items; new use case and provider | Zero impact on list path; domain intent is explicit; each entity carries only what its consumer needs; consistent with ADR-0008 | Field duplication of scalar fields across two entities; one extra file per layer; scalar field changes must be applied in two places |

## Decision

**Chosen:** Option 2 — introduce `IntakeRequestDetail` as a separate pure-Dart entity.

The beneficiary dashboard's `watchActiveDeliveries` stream is the highest-frequency Firestore listener in the beneficiary feature; it rebuilds on every status change across all active deliveries. Carrying item arrays through those rebuilds is unnecessary overhead with no display benefit — `ActiveDeliveryCard` never reads `items`. More fundamentally, the list and detail views are distinct read concerns: the list needs aggregate fields for a card summary, the detail needs item rows for an expanded view. Modelling them with separate entities makes each type self-documenting and independently evolvable. The field duplication cost (one mapper per layer) is low and bounded.

## Reversal Cost

Low — `IntakeRequestDetail` is consumed only by `DeliveryDetailScreen` and its provider. Merging it back into `IntakeRequest` is a contained refactor: delete the detail entity, add `items` to `IntakeRequest`, update one mapper, delete the detail use case and provider, point the screen at the existing `intakeRequestProvider`. No other feature is affected.

## Consequences

Easier: the `watchActiveDeliveries` stream and all list-path code paths are unaffected by changes to the detail view's data shape; item fields can evolve (e.g. adding `expiryTime` display) without touching `IntakeRequest`; each entity is independently unit-testable with minimal setup.

Harder: adding a new user-visible field that should appear in both the list card and the detail screen requires updating two domain entities, two mapper extension methods, and both provider/use-case chains; reviewers must check that scalar field changes are applied consistently in both entities.
