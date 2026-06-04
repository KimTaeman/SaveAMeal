# 0015 — Confirm Receipt: beneficiary-side closing mechanism

**Status:** PROPOSED
**Author:** architect
**Date:** 2026-06-04

## Problem

The SaveAMeal delivery loop closes today when the driver calls `confirmDelivery`, writing `status: 'delivered'` to the batch document. There is no subsequent beneficiary action in the app. A batch can sit in `delivered` indefinitely, producing an audit trail that reflects the driver's action rather than genuine beneficiary acknowledgement. PROP-0008 requires a decision on the mechanism used to transition `delivered → closed` from the beneficiary side and how to handle the scenario where the beneficiary never confirms.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Tap-to-confirm button on `DeliveryDetailScreen`; optimistic Hive write + Firestore update | Zero new infrastructure; uses existing security rule; single-tap UX; offline-capable via Hive | Batches stay `delivered` forever if beneficiary never opens app |
| 2 | Auto-close via Cloud Function timer (24 h after delivery) | Loop always closes; no UI change | Requires Cloud Functions + Cloud Tasks; `closed` reflects timeout not acknowledgement; races with driver writes |
| 3 | Rating/feedback form as the closing action | Collects feedback and closes in one interaction | Conflates mandatory acknowledgement with optional rating; forced form adds friction; couples two features |

## Decision

**Chosen: Option 1 — tap-to-confirm button with optimistic Hive update.**

A single "Confirm Receipt" button on `DeliveryDetailScreen` is the lowest-friction path that produces genuine beneficiary acknowledgement within the Firestore-only constraint. The Firestore `batches` security rules already permit beneficiaries to write `status` and `updatedAt` when the current status is `delivered`, so no backend change is required. Optimistic local update via Hive ensures the UI reflects `closed` immediately even if the device goes offline before the Firestore write completes.

## Reversal Cost

Low. The button, `_ConfirmationBanner`, and `ConfirmReceiptUseCase` are self-contained additions. Removing the feature requires deleting the use case, the repository method, the data layer implementation, and the two UI conditionals in `DeliveryDetailScreen` — approximately 4–6 files and no changes to existing domain interfaces. If a timer-based auto-close (Option 2) is later added as a supplementary mechanism, it does not conflict with Option 1 and can be deployed independently.

## Consequences

**Easier:** Donors and platform operators can query `status == 'closed'` to identify batches with confirmed beneficiary receipt, distinct from `status == 'delivered'` which reflects driver action only. The `ConfirmReceiptUseCase` boundary makes the acknowledgement step independently unit-testable. Rating/feedback remains a separable concern that can be added as a non-blocking follow-up action in a future proposal without touching the closing mechanism.

**Harder:** Batches where the beneficiary never opens the app after delivery will remain in `delivered` status indefinitely unless a supplementary mechanism (ops tool, admin bulk-close, or future timer) is introduced. The Hive optimistic cache must be correctly restored on Firestore write failure; the rollback path adds implementation complexity that must be covered by tests.
