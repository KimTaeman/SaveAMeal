# 0010 — Order history pagination: Future-based cursor vs. Stream-based infinite scroll

**Status:** SUPERSEDED by #0011
**Author:** architect
**Date:** 2026-06-03

## Problem

`BeneficiaryOrderHistoryScreen` must display a potentially long list of completed batches (`status in [delivered, closed]`) for a single beneficiary. Two approaches are viable: a real-time `Stream` (matches the pattern used throughout the rest of the app) or a `Future`-based cursor-paginated load with a manual "Load More" button. The choice affects UI complexity, Firestore read cost, and the shape of the Riverpod provider.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | `StreamProvider` over a single Firestore query with no pagination | Simplest code — one provider, real-time updates | Reads all delivered/closed batches on every snapshot; no upper bound on document reads for active beneficiaries; Firestore listener held open for a screen the user opens infrequently |
| 2 | `Future`-based cursor pagination via `StateNotifier` with "Load More" button (chosen) | Bounded read cost — exactly 10 documents per page; listener closed when user leaves screen; `AutoDispose` drops state when screen is popped | No real-time updates — new deliveries do not appear unless user manually refreshes; slightly more complex provider state |
| 3 | `StreamProvider` with client-side pagination using `limit` + `startAfter` on stream re-subscription | Real-time for the first page; cursor can advance | Re-subscription on cursor advance tears down and re-establishes the Firestore listener, costing one extra read burst; implementation complexity higher than option 2 |

## Decision

**Chosen:** Option 2 — `Future`-based cursor pagination via `@riverpod` class-based `StateNotifier`.

Order history is an archive view, not a live status feed. Delivered batches do not change status, so real-time updates carry no user value and introduce unnecessary read cost. A "Load More" button is a well-understood UX pattern on history screens. The `AutoDisposeNotifier` drops the entire state when the screen is popped, so the next visit always starts with a fresh first page — consistent with users expecting a fresh list when navigating back.

## Reversal Cost

Medium. Switching to a `StreamProvider` would require replacing `OrderHistoryNotifier` with a stream provider, removing `OrderHistoryState`, and updating the screen to drive from `AsyncValue` instead of `state.entries`. The domain repository interface method (`getOrderHistoryPage`) would need to change to `watchOrderHistory` returning a `Stream`. Three to five files affected; donor-side is unaffected.

## Consequences

**Easier:** Firestore read cost is bounded and predictable. Provider can be `autoDispose` without worrying about re-subscribing a listener. Test mocks are simpler (`Future` vs. `Stream`).

**Harder:** Newly delivered batches do not appear in the list without a page refresh. The `hasMore` flag logic must correctly detect the last page (returned fewer than 10 items). Cursor state (`lastBatchId`) must be preserved across `loadMore` calls without being reset by `ref.invalidate`.

---

> **Superseded by ADR-0011.** During SPEC-0005 approval review the repository contract was changed from `Future`-based to `Stream`-based to align with app-wide conventions and enforce domain purity. See [0011 — Stream-based repository interface for beneficiary account](./0011-stream-repository-and-domain-safe-cursor.md).
