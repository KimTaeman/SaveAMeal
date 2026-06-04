# 0008 — Beneficiary Impact Metrics: Server-Aggregated Counters vs. Client-Aggregated History

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-03

## Problem

The beneficiary Impact screen requires cumulative metrics (total meals, kg, CO2e, deliveries, per-category kg). The team must decide where aggregation lives: in the Cloud Function at write time (producing a single summary document), or on the Flutter client at read time (querying the full delivery history and summing). The Domain layer must remain pure Dart regardless of choice.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | **Server-aggregated counters** — `onDeliveryComplete` writes incremental `FieldValue.increment` updates to `impactMetrics/{beneficiaryId}`; Flutter streams that one document | Single-document read; minimal Firestore reads per session; real-time with one snapshot listener; offline-cache trivial (one doc) | Requires Cloud Function change; metrics are not back-fillable without a migration script; category map uses dot-notation `update()` to avoid nested-object replacement |
| 2 | **Client-aggregated history** — Flutter queries all delivery documents for the beneficiary and sums on the client | No Cloud Function change needed; full audit trail available for free | O(n) Firestore reads grow with delivery count; expensive at scale; requires composite index; no offline guarantee for full history; violates read-cost predictability |
| 3 | **Scheduled aggregation** — a separate scheduled Cloud Function recomputes metrics nightly | Clean separation of concerns; easy back-fill | Up to 24-hour stale data; added infrastructure complexity; overkill for MVP |

## Decision

**Chosen:** Option 1 — Server-aggregated counters written by `onDeliveryComplete`.

Extending the existing `onDeliveryComplete` trigger keeps aggregation co-located with the write event, guaranteeing eventual consistency without polling. A single-document stream is the cheapest possible Firestore read pattern and works seamlessly with Firestore's local persistence for offline support. The dot-notation `update()` constraint for nested map fields is a one-time implementation detail that is well-documented in this spec.

## Reversal Cost

**Medium.** Switching to client-aggregated history requires adding a new Firestore query in the datasource, a composite index, and removing the `impactMetrics/{beneficiaryId}` document. Switching to scheduled aggregation requires a new Cloud Function and accepting stale data. Neither path requires changes to the Domain layer (the `BeneficiaryImpactRepository` interface is implementation-agnostic).

## Consequences

**Easier:** Screen load is a single Firestore document read; offline degradation requires no special code beyond Firestore's default persistence; security rules are already correct.

**Harder:** Historical back-fill requires a one-off migration script to replay past deliveries through `FieldValue.increment` updates; the `byCategory` map requires two Firestore operations per delivery (a `set` with merge for scalar fields, then an `update` with dot-notation for nested map fields) to work around Firestore's nested-object replacement behavior.
