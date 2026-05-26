# 0007 — Batch item data model: embedded array vs. per-document vs. subcollection

**Status:** PROPOSED
**Author:** Kim Taeman
**Date:** 2026-05-23

## Problem

The existing `Batch` entity and `BatchModel` are single-item structures (`description`, `weightKg`, `portions`). The Figma design for the Log Surplus Batch flow treats a submitted batch as a collection of heterogeneous line items (name, category, kg, expiry time), each added individually before a single submit operation. The codebase must adopt one canonical representation for batch items before the flutter-engineer implements `LogBatchScreen` — a post-implementation migration would be destructive.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Embedded `List<BatchItem>` array on the `Batch` document | Single document read/write; existing `watchActiveBatchesForDonor` stream unchanged; Hive JSON cache unchanged in shape; dashboard summary fields remain correct via computed getters | Breaking change to `Batch` entity and `BatchModel`; 1 MB Firestore document limit if items grow very large |
| 2 | One `Batch` document per item, grouped by a `batchGroupId` field | Zero change to existing `Batch` schema | Semantically wrong — dashboard shows N cards for one logical submission; QR/batch number is ambiguous across documents; driver assignment must be replicated N times |
| 3 | Subcollection `batches/{id}/items/{itemId}` | Most normalized; item-level queryability; no document size concern | Breaks `watchActiveBatchesForDonor` (requires async fan-out per batch); breaks Hive write-through cache; doubles cold-start read latency; no current feature requires item-level queries |

## Decision

**Chosen:** Option 1 — Embedded `List<BatchItem>` array.

The embedded array keeps the Firestore read path as a single document query, which is the contract that `watchActiveBatchesForDonor`, `DonorRepositoryImpl`, and the Hive cache all depend on. The existing `description`, `weightKg`, and `portions` fields are converted to computed getters derived from the items list, preserving backward compatibility with all dashboard rendering code without any dashboard-side changes. No current or near-term feature requires item-level independent querying, so the normalization benefit of a subcollection does not justify the read-path complexity it introduces.

## Reversal Cost

**High.** Migrating from an embedded array to a subcollection requires a one-time Firestore data migration script to move existing item arrays into new subcollection documents, a rewrite of the `DonorRepositoryImpl` read path, and a redesign of the Hive cache serialization. Any batch documents written under the embedded model would need to be back-filled. Reverting to Option 2 (per-document) would require merging existing multi-item batch documents and is also destructive.

## Consequences

**Easier:**
- Single Firestore `set` call submits an entire batch with all items atomically.
- Dashboard stream, Hive cache, and all existing mapper code require only additive changes (no structural rewrites).
- The `BatchSummaryScreen` session state (`List<BatchItem>`) maps directly to the submitted document with no transformation layer.

**Harder:**
- Any future requirement to query "all batches containing a Dairy item" cannot be answered by a Firestore collection query — it would require a client-side filter or a denormalized index.
- If a single donor batch routinely contains 50+ items with large metadata, document size must be monitored.
- Freezed codegen must be re-run whenever `BatchItem` or `BatchModel` changes, adding a step to the dev loop.
