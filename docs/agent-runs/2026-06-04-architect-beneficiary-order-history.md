# Architecture Review — SPEC-0007 Beneficiary Order History

**Reviewer:** architect
**Session ID:** beneficiary-order-history
**PR / Branch:** feat/beneficiary-order-history
**Date:** 2026-06-04

---

## Summary

29 files, 3 017 insertions reviewed against SPEC-0007 and the strict Clean Architecture contract (domain layer must have zero Flutter or Firebase imports). All six domain-layer files are confirmed pure Dart. The data layer correctly absorbs the Firestore `DocumentSnapshot` type and never surfaces it through a domain return type. The presentation layer carries one design smell (Hive I/O inside a Riverpod notifier) that is non-blocking given the existing project precedent. One unused Firestore composite index in `firestore.indexes.json` and one `copyWith` semantic issue are flagged as design notes. No blocking violations were found.

---

## Layer Boundary Violations

None found. All domain files are clean:

- `delivery_history_page.dart` — imports only `domain/entities/recent_delivery.dart`. `nextCursor: Object?` erases the `DocumentSnapshot` type at the boundary. Zero Flutter or Firebase imports. PASS.
- `recent_delivery.dart` — zero imports. Pure Dart value object with nullable `category: String?` field. PASS.
- `intake_repository.dart` — imports only `domain/entities/` files. Abstract method signature uses `Object? cursor` — no Firestore types visible. PASS.
- `fetch_delivery_history_page_usecase.dart` — imports only `domain/entities/` and `domain/repositories/`. PASS.
- `firestore_intake_repository.dart` — data-layer file; Firebase imports here are correct. Receives `(List<BatchModel>, Object?)` from the datasource, maps to `RecentDelivery`, returns `DeliveryHistoryPage`. The `nextCursor` value (a `DocumentSnapshot` in practice) is stored as `Object?` in the domain entity and never cast or typed in any domain file. The repository never unwraps the `DocumentSnapshot` — it passes it opaquely back to the datasource on the next call via `cursor: current.cursor`. PASS.

---

## Design Notes

### 1. Hive cache management in the presentation/provider layer (non-blocking)
`DeliveryHistoryNotifier` in `presentation/providers/` directly opens a `Hive.box<String>('delivery_history_cache')` and performs `box.get`, `box.put`, and `box.delete` operations. Cache I/O is a data-layer concern under Clean Architecture; the correct home is an `IntakeCacheDatasource` implementing a cache datasource interface, with the repository composing the remote and cache datasources. However, the existing project uses the same pattern in donor notifiers, so enforcing a stricter boundary now would require refactoring existing code. This is acceptable for MVP and is documented as a known divergence. Track as a tech debt item to move cache I/O to the data layer before the feature set grows.

### 2. `build()` always fires a network call even when a warm cache exists
On every provider build (i.e., every time the screen opens or the provider is re-created after disposal), `build()` fires `fetchDeliveryHistoryPage` unconditionally — the cached items are read only to be replaced immediately by the network result. The design intent is to always show fresh data, which is correct for a history screen. The cost is one Firestore read per screen open, which is acceptable at current scale. If Firestore billing becomes a concern, the path is to skip the network call when cache age is under a configurable TTL (e.g., 5 minutes). This is a non-blocking design note.

### 3. `copyWith` always resets `loadMoreError` to the passed value (including null)
`DeliveryHistoryState.copyWith` does not use `?? this.loadMoreError` for the `loadMoreError` parameter — it always sets it to whatever is passed. This is intentional: passing `loadMoreError: null` clears the previous error, which is the correct behavior for clearing errors on retry (`copyWith(isLoadingMore: true, loadMoreError: null)`). However, callers that do not pass `loadMoreError` at all will receive `null` for it, silently clearing any existing error. This is only called in two places (both of which explicitly pass the intended value), so it is not a current bug, but it is a footgun for future callers. Consider an explicit sentinel value (e.g., a `const _keep = Object()` default) or a dedicated `clearError()` method to make the intent unambiguous.

### 4. `kDeliveryHistoryPageSize` defined in the use case file
`const int kDeliveryHistoryPageSize = 20` is defined at the top of `fetch_delivery_history_page_usecase.dart`. This is correct: it is a domain-adjacent constant that belongs with the use case that enforces it. It should not live in the data or presentation layer. No issue.

### 5. `portions` derived from `batch.items.length` at mapping time
In both `watchRecentDeliveries` and `fetchDeliveryHistoryPage` mappers, `portions: b.items.length` is used. If `items` is ever empty for a delivered batch (e.g., legacy records or a schema migration), `portions` will be 0. The stats bar computes total meals from this field. This is an existing limitation in `watchRecentDeliveries` and is not introduced by this PR — it is carried forward consistently. No new violation.

---

## Schema Consistency

### Unused composite index (informational)
`firestore.indexes.json` contains two indexes:

1. `beneficiaryId ASC + status ARRAY_CONTAINS + deliveredAt DESC` — this was the originally planned index for the order history query. The final Firestore query omits `orderBy` (to avoid needing this index), and sorting is done client-side in the repository. This index is therefore unused by any current query. An undeployed, unused index creates confusion about which indexes the query actually requires.

**Recommended action:** Remove this index from `firestore.indexes.json`. If the team later adds `orderBy('deliveredAt', descending: true)` to the Firestore query, add it back at that time. Keeping it "for future use" in a version-controlled schema file is misleading — it implies the index is required now.

2. `beneficiaryId ASC + status ASC + createdAt DESC` — carried from main branch, used by an existing query. No issue.

---

## Checklist

- [x] Domain entities contain zero Flutter or Firebase imports
- [x] Repository interfaces contain zero Flutter or Firebase imports
- [x] Use cases contain zero Flutter or Firebase imports
- [x] Data layer correctly implements domain interfaces
- [x] Firestore cursor type (`DocumentSnapshot`) does not leak into domain return types
- [x] `Object?` cursor pattern preserves domain purity
- [x] Presentation layer imports only domain layer (no direct data layer imports)
- [x] Riverpod override pattern in widget tests follows Riverpod 3.x conventions
- [x] Unit tests use hand-rolled fakes consistent with existing test patterns
- [x] `kDeliveryHistoryPageSize` defined at domain-adjacent layer (use case file)
- [ ] Hive cache I/O belongs in data layer — currently in presentation/provider layer (known project-wide pattern; non-blocking)
- [ ] Unused Firestore composite index in `firestore.indexes.json` should be removed

---

## Verdict

**APPROVED**

Reason: All domain layer files are confirmed pure Dart with zero Flutter or Firebase imports; the `Object?` cursor pattern correctly encapsulates the `DocumentSnapshot` within the data layer; the two non-blocking items (Hive in the notifier and the unused Firestore index) are consistent with existing project patterns or easily remedied in a follow-up commit.
