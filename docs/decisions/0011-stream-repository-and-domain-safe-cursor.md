# 0011 — Stream-based repository interface for beneficiary account; domain-safe String cursor supersedes DocumentSnapshot cursor

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-03

## Problem

Two design decisions were revisited during the SPEC-0005 approval review:

1. ADR-0010 chose `Future`-based cursor pagination for order history. The spec review mandated replacing `getOrderHistoryPage(Future)` with `watchOrderHistory(Stream)` to align the repository interface with the app-wide convention of Stream-returning repositories (cf. `WatchActiveBatchesUsecase` in the donor feature).

2. The initial stream signature draft proposed `watchOrderHistory(String uid, {DocumentSnapshot? cursor, int limit})` — using `DocumentSnapshot` directly in the domain repository interface. `DocumentSnapshot` is a `cloud_firestore` type, which would break the domain purity rule (zero Flutter or Firebase imports in any domain file).

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Keep `Future`-based `getOrderHistoryPage` (ADR-0010) | Bounded reads; simpler state model | Inconsistent with every other repository in the codebase that returns `Stream`; harder to compose with other stream providers |
| 2 | `Stream<List<OrderHistoryEntry>> watchOrderHistory` with `DocumentSnapshot? cursor` | Live updates; matches app-wide Stream convention | `DocumentSnapshot` is a Firebase type — importing it in the domain repository violates the domain purity rule enforced by architecture |
| 3 | `Stream<List<OrderHistoryEntry>> watchOrderHistory` with `String? cursor` (chosen) | Live updates; matches app-wide Stream convention; domain layer remains pure Dart with zero Firebase imports; datasource resolves the String ID to a `DocumentSnapshot` internally | Datasource must perform one extra Firestore `.get()` call to resolve the cursor ID before opening the stream; negligible cost for a paginated archive screen |

## Decision

**Chosen:** Option 3 — `Stream<List<OrderHistoryEntry>> watchOrderHistory(String uid, {String? cursor, int limit = 10})` on both the repository interface and the use case. The datasource resolves `cursor` (a batch document ID) to a `DocumentSnapshot` internally before passing it to `startAfterDocument`. ADR-0010 is superseded by this record.

Domain purity is a hard architectural rule: zero Firebase imports in any domain file. Passing `DocumentSnapshot` through the repository interface would require importing `cloud_firestore` in `beneficiary_account_repository.dart`, a domain file, which is not permitted. The String cursor is an opaque identifier at the domain level; its resolution to a Firestore cursor is an implementation detail of the data layer — exactly the kind of concern Clean Architecture assigns to that layer. The Stream return type aligns this repository with every other repository in the codebase.

## Reversal Cost

Low for the cursor type: swapping `String? cursor` back to `DocumentSnapshot? cursor` on the repository interface requires changing two files (repository interface, use case) and adding a `cloud_firestore` import to the repository — but that immediately violates domain purity and would require a separate rule exception to be documented. Reverting the Stream back to Future (to restore ADR-0010) requires updating the repository interface, repository implementation, datasource interface, use case, and provider — five files, no regression risk on screens already built against the Stream shape.

## Consequences

**Easier:** Domain layer stays pure Dart, enforcing the zero-import rule across all feature boundaries. Stream convention is consistent across the entire codebase. Providers can compose with `StreamProvider` natively.

**Harder:** Datasource must perform an extra `.get()` call to resolve the cursor String to a `DocumentSnapshot` before re-subscribing the stream with `startAfterDocument`. The `OrderHistoryNotifier` must manage stream subscription cancellation on `loadMore` to avoid duplicate listeners. Tests must mock a `Stream` return type instead of a `Future`.
