---
title: "0007: Beneficiary Order History"
description: "Add a paginated, offline-readable full delivery history screen for beneficiaries, reachable from the existing no-op 'View All' button in RecentDeliveriesSection."
---

# PROP-0007: Beneficiary Order History

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-04
**Spec:** (pending approval)
**Approved by:** nadi

---

## Problem

Beneficiaries can see the three most-recent completed deliveries in `RecentDeliveriesSection` on the dashboard. That section has a "View All" `TextButton` whose `onPressed` is currently a no-op (`() {}`). There is no screen behind it. A beneficiary who wants to verify what they received last month, confirm a donor's name, or review a disputed delivery count has no way to do so inside the app.

The underlying data mechanism — `watchRecentDeliveriesForBeneficiary` in `FirestoreService` — queries `batches` filtered by `beneficiaryId` and `status IN ['delivered','closed']` with a hard `limit(20)`, then sorts client-side and slices to 3. This is adequate for a 3-item preview but unsuitable for a full history screen:

1. A beneficiary with more than 20 completed deliveries silently loses older records (the `limit(20)` cuts the query before client-side sort runs, so the oldest 20 documents returned by Firestore may not be the 20 most-recent ones).
2. A live Firestore stream holding `N` complete delivery documents open for the lifetime of the screen is wasteful and does not compose with pagination — the entire result set re-emits on every change to any document in scope.
3. There is no cursor to advance to the next page of results.

The existing `RecentDelivery` domain entity (`batchId`, `deliveredAt`, `portions`, `donorName`) contains exactly the right fields to populate a history list row; no new entity fields are required by the list itself. What is missing is a pagination-capable data access path and a dedicated screen.

---

## Goals

- Provide a full, paginated delivery history list screen for beneficiaries.
- Support offline / cached reading: previously-loaded pages must render without a live network connection.
- Use cursor-based Firestore pagination (`startAfterDocument`) so history never loads all at once.
- Wire the existing no-op "View All" button in `RecentDeliveriesSection` to the new screen.
- Allow tapping a history row to navigate to the existing `DeliveryDetailScreen` (`/beneficiary/delivery/:batchId`).
- Keep the domain layer pure Dart: no Firestore types or Flutter imports inside `domain/`.

---

## Non-goals

- Donor or admin views of a beneficiary's history (different role, different feature).
- Editing, disputing, or annotating history records.
- Real-time live-updating list: pagination via `startAfterDocument` requires `Future`-based fetching, not a continuous `Stream`. The list does not need to update while the user is reading it.
- Nutrition or CO2 analytics per delivery row (that is the responsibility of `BeneficiaryImpactScreen`).
- Exporting or sharing history data.
- Filtering or searching history (can be added later without architectural change).

---

## Options

### Option A — New dedicated `DeliveryHistoryScreen` with cursor-based pagination (Recommended)

**Description.** Add a new route `/beneficiary/history` and a new screen `DeliveryHistoryScreen`. The screen is backed by a new `AsyncNotifier` (Riverpod `@riverpod` code-gen) that manages a mutable list of `RecentDelivery` plus a Firestore `DocumentSnapshot` cursor. On first load and on "load more" trigger (via a `ScrollController` listener or a manual "Load More" button), the notifier calls a new use case `FetchDeliveryHistoryPageUseCase` which executes a `Future`-based Firestore query: `batches` filtered by `beneficiaryId + status IN ['delivered','closed']`, ordered by `deliveredAt DESC`, `limit(pageSize)`, `startAfterDocument(cursor)`. Each page result is appended to the notifier's list. Hive is used as an explicit page cache: on each successful page fetch, the serialised `List<RecentDelivery>` for that page is written to a Hive box keyed by `beneficiaryId + pageIndex`; on notifier initialisation, the cached first page is loaded immediately before the network fetch completes, giving instant offline render.

**Pros.**

- Clean separation of concerns: the history screen has its own route, its own notifier, its own use case, and its own cache — none of the existing providers or widgets are mutated.
- `Future`-based fetching is the correct primitive for paginated reads; it does not leave a long-lived stream listener open on a growing result set.
- Hive page cache gives genuine offline read for previously-loaded pages at negligible cost (the app already depends on `hive_flutter` per ADR-0003).
- `RecentDelivery` entity is already the right shape for list rows — no new domain entity needed.
- The use case boundary makes the notifier trivially unit-testable: mock `FetchDeliveryHistoryPageUseCase`, verify the notifier appends results and advances the cursor.
- `DeliveryHistoryScreen` is completely independent of `BeneficiaryImpactScreen`; adding or removing one has no effect on the other.

**Cons.**

- Requires a composite Firestore index on `batches`: `(beneficiaryId ASC, deliveredAt DESC)` — this is a one-time index definition in `firestore.indexes.json`.
- New files: one domain use case, one domain repository method addition (`fetchDeliveryHistoryPage`), one data implementation, one Riverpod notifier, one screen, one or two widgets, one Hive adapter or manual serialiser for `RecentDelivery` cache entries.
- The Hive page cache is a write-through cache that must be invalidated if delivery records are ever mutated (unlikely for history, but a consideration).

**Effort:** M (medium — approximately 8–12 new or modified files, no new dependencies).

---

### Option B — Extend `BeneficiaryImpactScreen` with a lazy-loaded delivery history section

**Description.** Add a scrollable "Delivery History" section below the existing stats cards in `BeneficiaryImpactScreen`. A `ScrollController` on the existing `SingleChildScrollView` detects when the user nears the bottom and triggers additional data loads. The existing `beneficiaryImpactProvider` is left untouched; a second provider for history data is watched inside the same screen.

**Pros.**

- No new route or screen scaffold; the "Impact" tab already exists in the bottom navigation.
- Reduces the navigation surface — history is reached by scrolling down on a tab the user already visits.
- Fewer new files than Option A.

**Cons.**

- `BeneficiaryImpactScreen` already has a defined scope (aggregate metrics, CO2, by-category breakdown). Mixing delivery history into it conflates two concerns in one screen and one scroll viewport. Future changes to either concern require touching the same file.
- The existing `SingleChildScrollView` wraps `shrinkWrap: true` `ListView.builder` children. Adding paginated history data at the bottom means the `ScrollController` must coordinate with the `shrinkWrap` list, which is a known source of scroll physics bugs in Flutter — the inner list competes with the outer scroll for gesture handling.
- "View All" from `RecentDeliveriesSection` on the dashboard cannot navigate to a mid-screen position inside `BeneficiaryImpactScreen` without a fragile `ScrollController.animateTo` call with a hardcoded offset.
- There is no clean offline cache story: the Impact screen uses a single Firestore document stream (ADR-0008); adding paginated history adds a second, structurally different data source with different cache requirements into the same screen lifecycle.
- The "Impact" tab label and icon (`Icons.favorite`) do not communicate "history"; discoverability is worse than a dedicated screen reached from "View All".

**Effort:** M (medium — same data layer work as Option A, but saved by not needing a new route; offset by the scroll physics complexity).

---

### Option C — Reuse `watchRecentDeliveries` with a custom `StreamController` that emits pages

**Description.** Replace the current `watchRecentDeliveries` implementation with a new `WatchDeliveryHistoryUseCase` that owns a `StreamController<List<RecentDelivery>>`. A method `loadNextPage()` fires a Firestore query and pushes the accumulated result list into the stream. The existing `recentDeliveriesProvider` is widened to expose `loadNextPage`. `RecentDeliveriesSection` continues to use the same provider, just sliced to 3.

**Pros.**

- A single provider serves both the 3-item preview and the full history list.
- No new route required if the history is rendered inside an existing screen.

**Cons.**

- This is the most architecturally complex option. A `StreamController` that mixes reactive push (Firestore snapshots) with imperative pull (`loadNextPage()`) is a hybrid that is difficult to reason about and test. The existing `watchVolunteerQueue` in `FirestoreService` already uses this pattern and its complexity is commented on inline.
- The existing `recentDeliveriesProvider` is a `Stream` provider; converting it to an `AsyncNotifier` or `StateNotifier` with a mutable page list is a breaking change to the existing `RecentDeliveriesSection` consumer.
- Widens a provider that currently has a single, narrow responsibility (3-item preview) into a general-purpose paginator, violating the single-responsibility principle.
- Hive caching is still needed but harder to apply to an accumulating stream.

**Effort:** L (large — high implementation complexity and high risk of regressions in the existing `RecentDeliveriesSection`).

---

## Recommendation

**Option A — New dedicated `DeliveryHistoryScreen` with cursor-based pagination.**

Option A is the only approach that satisfies both the offline/cache constraint and the pagination constraint without architectural compromise. A `Future`-based `AsyncNotifier` with cursor advancement is the idiomatic Riverpod pattern for paginated reads; Hive page cache provides offline readability at no additional dependency cost; and a dedicated screen/route keeps `BeneficiaryImpactScreen` and `RecentDeliveriesSection` fully unchanged.

Option B saves one route at the cost of entangling two unrelated concerns in a single screen and introducing scroll-physics complexity that has historically caused defects in Flutter. Option C is strictly more complex than Option A for no structural benefit; the hybrid `StreamController` pattern should not be added to the codebase a second time.

The reversal cost of Option A is low: the new screen, notifier, use case, and Hive cache are self-contained. Removing the feature means deleting approximately 6–8 files and the route registration — nothing in the existing history is changed.

---

## Open Questions

1. **Composite Firestore index.** A query ordered by `deliveredAt DESC` filtered by `beneficiaryId` requires a composite index on `batches`: `(beneficiaryId ASC, deliveredAt DESC)`. Does this index already exist in `firestore.indexes.json`? If not, it must be added before the data layer implementation can be tested against a live project. Who owns the `firestore.indexes.json` file and is there a deployment step required?

2. **Row tap navigation.** Should tapping a row in `DeliveryHistoryScreen` navigate to `/beneficiary/delivery/:batchId` (`DeliveryDetailScreen`)? The `DeliveryDetailScreen` implemented under PROP-0006 is designed for active deliveries (status-step indicator, volunteer info). A completed delivery row would show a fully-terminal status. This is useful context, but the screen may need a visual adjustment (e.g. hiding the ETA field) for completed batches. Should the spec include that adjustment, or should the history row be non-tappable in the first iteration?

3. **Page size.** What is the correct page size — 10 or 20 items per page? 10 is conservative (fewer Firestore reads per session, faster first paint) but may feel paginator-heavy for a user with 50+ deliveries. 20 matches the current `limit(20)` used by the preview query. The page size should be a named constant (`kDeliveryHistoryPageSize`) defined once in the use case file.

4. **Hive cache invalidation.** The Hive page cache stores serialised `RecentDelivery` lists keyed by page index. Delivery records in Firestore are immutable once `status` reaches `delivered` or `closed`, so cache invalidation is not required in normal operation. However, if a batch document is retroactively corrected (e.g. `donorName` is updated), the cached page will serve stale data until the cache is cleared. Is a max-age TTL on cache entries needed, or is a "pull to refresh" that clears the cache sufficient for MVP?

5. **Empty state.** What should `DeliveryHistoryScreen` render for a new beneficiary with zero completed deliveries? An illustration with explanatory text ("Your delivery history will appear here") or a simple text label? This affects widget design but not architecture.

---

## Acceptance Criteria

**Domain layer**

- `IntakeRepository` declares a new method `Future<List<RecentDelivery>> fetchDeliveryHistoryPage({required String beneficiaryId, required int pageSize, Object? cursor})` where `cursor` is an opaque type (typed as `Object?` in the interface so the domain layer holds no Firestore reference types).
- A new use case `FetchDeliveryHistoryPageUseCase` in `domain/usecases/` has a `call` method that delegates to `IntakeRepository.fetchDeliveryHistoryPage` and returns `Future<List<RecentDelivery>>`. It has zero Flutter or Firestore imports.
- `FetchDeliveryHistoryPageUseCase` is unit-testable with a mock repository: given a mock that returns a fixed list, the use case returns the same list unmodified.

**Data layer**

- `FirestoreIntakeRepository` implements `fetchDeliveryHistoryPage` by querying `batches` with `where('beneficiaryId', isEqualTo: beneficiaryId)`, `where('status', whereIn: ['delivered', 'closed'])`, `orderBy('deliveredAt', descending: true)`, `limit(pageSize)`, and `startAfterDocument(cursor)` when `cursor` is non-null.
- The method returns a `Future<List<RecentDelivery>>` (not a stream).
- The concrete `DocumentSnapshot` cursor is captured inside the repository and returned as `Object?` so that the domain use case and the notifier hold it without importing Firestore types.
- Firestore `DocumentSnapshot`, `QuerySnapshot`, and related types do not appear outside `data/datasources/` or `services/`.

**Presentation layer**

- A new `@riverpod` `AsyncNotifier` `DeliveryHistoryNotifier` (in `presentation/providers/`) maintains: `List<RecentDelivery> items`, `bool hasMore`, `Object? _cursor`. It exposes a `loadNextPage()` method.
- On first build, the notifier loads from the Hive page cache (if populated) before firing the network request, so the screen renders cached data immediately.
- Each successful network page is written to Hive, keyed by `beneficiaryId + pageIndex`.
- A new screen `DeliveryHistoryScreen` at route `/beneficiary/history` consumes `DeliveryHistoryNotifier`.
- The screen renders a `ListView.builder` (never unbounded `ListView`) of `_DeliveryHistoryRow` widgets.
- The last item in the list is a "Load More" button (or an auto-trigger via `ScrollController`) that calls `notifier.loadNextPage()`. When `hasMore` is false, no trigger is shown.
- While the initial load is in progress, a `CircularProgressIndicator` is shown.
- When the notifier is in error state and no cached data is available, an error widget with a retry button is shown.
- When no deliveries exist (empty first page), an empty-state widget is shown.
- Tapping a row navigates to `/beneficiary/delivery/:batchId`.
- The `RecentDeliveriesSection` "View All" `TextButton`'s `onPressed` is wired to `context.push('/beneficiary/history')`.
- All colours use `cs.*` or `ac.*` — no hardcoded colour values.
- All text styles use `Theme.of(context).textTheme.*` — no hardcoded font sizes.
- All spacing uses the project spacing scale — no magic numbers.
- All remote images (if any) go through `CachedNetworkImage`.

**Firestore**

- A composite index on `batches`: `(beneficiaryId ASC, deliveredAt DESC)` is defined in `firestore.indexes.json` and deployed before the data layer is tested against a live project.

**Tests**

- A widget test for `DeliveryHistoryScreen` covers: initial loading state, populated list with multiple rows, empty state (zero deliveries), error state with retry, and "Load More" button visibility when `hasMore` is true vs. false.
- A unit test for `FetchDeliveryHistoryPageUseCase` verifies delegation to the repository and correct forwarding of `beneficiaryId`, `pageSize`, and `cursor` arguments.
- A unit test for `DeliveryHistoryNotifier` verifies: first `loadNextPage` call populates the list; second call appends to the list; when the returned list length is less than `pageSize`, `hasMore` is set to false.

**Architecture constraints**

- `DeliveryHistoryScreen` imports from `domain/` and `presentation/` only — no import of any `data/` type.
- `FetchDeliveryHistoryPageUseCase` imports only from `domain/` — no Flutter, Riverpod, or Firestore imports.
- `flutter analyze` reports zero new warnings after implementation.
- `dart format .` is run before the PR is submitted.
