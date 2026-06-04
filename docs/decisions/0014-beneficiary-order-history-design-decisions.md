# 0014 — Beneficiary Order History: `category` field, aggregate stats source, and display ID format

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-04

## Problem

SPEC-0007 (Beneficiary Order History) required three design decisions that affect the domain entity shape and data access pattern: (1) whether to add a `category` field to `RecentDelivery` and how to derive it from `BatchModel`; (2) how to source the "Total Meals" and "Deliveries" aggregate stats shown in the Figma stats bar; (3) how to display a human-readable "Order #..." identifier when `BatchModel` has no such field.

## Options Considered

### D1 — `category` on `RecentDelivery`

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Add `category: String?`; mapper reads `batch.items.first?.category` | Minimal entity growth; nullable = backwards-compatible | First-item choice is arbitrary for mixed-category batches |
| 2 | Add `categories: List<String>`; display first or join | Accurate for mixed batches | Entity grows; display logic becomes complex |
| 3 | Store preformatted `categoryLabel: String?` in mapper | Display-ready | Bakes display logic into the data layer; not localisable |

### D2 — Aggregate stats source

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Read from a `beneficiaryStats` Firestore document (Cloud Functions) | O(1) read; always accurate | Requires Cloud Functions write path not yet built |
| 2 | Firestore `count()` + `sum(portions)` aggregate queries | Always accurate; no Cloud Functions | Two extra Firestore reads per screen open; `sum()` aggregate needs SDK v9.20+ |
| 3 | Compute from loaded pages only (client-side) | Zero extra reads; no new infrastructure | Approximate until all pages are loaded |

### D3 — Display order identifier

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | `#${batchId.substring(0, 8).toUpperCase()}` in the presentation widget | Zero schema change | Looks like a hash; not sequential or memorable |
| 2 | Add `orderNumber: String` to `BatchModel` via Cloud Functions | Clean, human-memorable | Requires Cloud Functions and schema addition — out of scope |
| 3 | Display truncated `batchId` labelled "Ref" to set correct expectations | Honest label | Deviates from Figma copy |

## Decision

**D1 — Chosen: Option 1.** Add `category: String?` to `RecentDelivery`. The mapper reads `batch.items.isNotEmpty ? batch.items.first.category : null`. This field is nullable so all existing callers (`RecentDeliveriesSection`, `watchRecentDeliveries`) are unaffected — they ignore the field. The first-item heuristic is sufficient for the vast majority of batches (which carry a single food category) and is documented with a `// TODO: majority-category if batches become mixed` comment in the mapper.

**D2 — Chosen: Option 3.** For MVP, stats are computed client-side from `DeliveryHistoryState.items` (loaded pages only). The stats bar shows a disclaimer note ("*Showing totals for loaded deliveries") when `hasMore == true`. The upgrade path to exact totals is Option 1 (Cloud Functions + `beneficiaryStats` document), which requires no domain interface change — only the stats bar widget's data source is replaced.

**D3 — Chosen: Option 1.** The display identifier is formatted in the presentation widget as `'#${delivery.batchId.substring(0, 8).toUpperCase()}'`. No new field is added to `BatchModel` or `RecentDelivery`. This is a display concern only. If sequential order numbers are added later, only the widget (or a new `displayId` field in `RecentDelivery`) needs updating — the repository method signature and domain interfaces are unchanged.

## Reversal Cost

**D1:** Low. Removing the `category` field from `RecentDelivery` is a one-line change plus updating the two mappers that set it and the one widget that reads it. Existing callers that ignore it are unaffected.

**D2:** Low. Replacing client-side computation with a `beneficiaryStats` document read requires adding a provider and changing the stats bar widget's data source. The domain interface (`IntakeRepository`) is unchanged.

**D3:** Low. Replacing the hash-prefix format with a real order number requires adding `orderNumber: String?` to `BatchModel`, populating it via Cloud Functions, and updating the mapper. The `_DeliveryHistoryRow` widget reads `delivery.batchId` directly — no domain entity change.

## Consequences

**Easier:** `RecentDelivery` entity carries enough information for a visually rich history row without requiring a separate entity or a breaking change to existing consumers. The stats bar requires no new Firestore reads, keeping the screen fast to open. Display formatting stays in the presentation layer where it belongs.

**Harder:** Stats are approximate until all pages are loaded, which may confuse users who notice the numbers change as they scroll. The first-item category heuristic will be wrong for genuinely mixed batches (e.g. a batch with half hot meals and half produce). Both issues are documented and tracked as open questions in SPEC-0007.
