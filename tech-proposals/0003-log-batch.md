---
title: "0003: Log Surplus Batch — multi-item entry flow"
description: "Implement the LogBatchScreen 3-screen flow (scanner → form → summary) and resolve the single-item vs. multi-item data model conflict before any code is written."
---

# PROP-0003: Log Surplus Batch — multi-item entry flow

**Status:** ACCEPTED
**Author:** Kim Taeman
**Date:** 2026-05-23
**Spec:** (pending approval)
**Approved by:** (fill in when accepted)

---

## Problem

`LogBatchScreen` is a single-line stub (`Text('TODO: implement batch logging form')`). The FAB on `DonorDashboardScreen` and the "Log Surplus Batch" button navigate to `/donor/log`, which renders nothing useful. `CreateBatchUsecase` and the Firestore write path through `FirestoreService.createBatch` are both implemented and wired; the missing piece is every layer above that call — the UI flow, the Riverpod form state, and the screen-level navigation.

There is also a structural mismatch that must be resolved before implementation starts:

The existing `Batch` entity and `BatchModel` model a **single item** — one `description`, one `weightKg`, one `portions` field. The Figma design (frames `13:199`, `53:10`, `53:201`) models a **multi-item batch**: a donor adds one item at a time through a scanner-and-form flow, accumulates them in a summary list, then submits the whole set in one operation. In the example shown in the Figma file, a single submitted batch contains "Mixed Bakery Goods 15 kg", "Fresh Produce 25 kg", and "Dairy Products 5 kg" — three distinct line items with separate names, categories, and expiry times under one batch document.

If this conflict is not resolved at the data model level before the flutter engineer writes code, the implementation will either (a) silently drop all items after the first, producing a regression in UX fidelity, or (b) require a breaking schema migration immediately after the first merge.

The three specific gaps that block this feature:

1. `LogBatchScreen` is a stub — no form, no scanner integration, no navigation flow.
2. `Batch` entity and `BatchModel` have no concept of line items — there is no `BatchItem` or equivalent structure anywhere in the codebase.
3. `StorageService.uploadBatchPhoto` throws `UnimplementedError` — the photo upload path is not wired.

---

## Proposed Solution

**Option A — Embedded items array** (recommended; see justification below).

Introduce a `BatchItem` value object in the Domain layer and embed a `List<BatchItem>` on both `Batch` and `BatchModel`. The existing `description`, `weightKg`, and `portions` fields on `Batch` are **retained as computed summaries** (derived at write time from the items list) so that the `watchActiveBatchesForDonor` Firestore query, `DonorRepositoryImpl` mappers, and `_BatchCard` on the dashboard continue to work without modification.

### New domain value object

```
features/donor/domain/entities/batch_item.dart   (new, pure Dart)

class BatchItem {
  final String name;          // product name (from barcode or manual entry)
  final String category;      // enum or string — see Open Question 3
  final double weightKg;
  final DateTime expiryTime;
  final String? photoUrl;     // uploaded after submit; null at creation time
}
```

### Changes to existing domain entity

`Batch` gains one field and two computed getters:

```dart
final List<BatchItem> items;   // required, non-empty at submit time

// Computed summaries — kept for backward compatibility with dashboard
double get weightKg  => items.fold(0, (s, i) => s + i.weightKg);
int    get portions  => items.length;
String get description => items.map((i) => i.name).join(', ');
```

The field-level `weightKg`, `portions`, and `description` on `Batch` are removed as stored fields and replaced with the getters above. `BatchModel` stores the items array in Firestore and recomputes the summaries on serialization so the dashboard's `subtitle` string (`'${batch.portions} items • ${batch.weightKg}kg'`) continues to render correctly.

### Screen flow

```
/donor/log  →  ScannerScreen  →  LogSurplusFormScreen  →  BatchSummaryScreen
                    ↑                                              |
                    └────── "Add Another Item" loops back ─────────┘
```

- `ScannerScreen` (frame `13:199`): full-screen `MobileScanner` viewfinder. On decode, stores the barcode string in a `StateProvider` and pushes to `LogSurplusFormScreen` with `productName` pre-filled. A bottom-sheet "Enter Manually" button pushes to the form with no pre-fill.
- `LogSurplusFormScreen` (frame `53:10`): form with Product Name, Category (dropdown), Quantity (kg), Expiry Time (time picker), Beneficiary (optional dropdown), Photo (optional upload). "Add to Batch" validates inline, appends a `BatchItem` to a `StateNotifierProvider<List<BatchItem>>` scoped to the batch session, and navigates to `BatchSummaryScreen`.
- `BatchSummaryScreen` (frame `53:201`): renders the accumulated `List<BatchItem>` in a `ListView.builder`. "Add Another Item" pops back to the scanner. "Submit Batch #XXXX" calls `CreateBatchUsecase` with a fully constructed `Batch`, uploads any pending photos to Firebase Storage, then navigates to `/donor`.

### QR code and batch number

`QrService.generateQrData` already exists and returns `saveameal://batch/<batchId>`. The batch `id` is a UUID generated client-side at the start of the session. The `qrCode` field on `Batch` is set to the output of `generateQrData(id)` before calling `createBatch`. The human-readable "Batch #XXXX" label on the summary screen is the first 4 characters of the UUID uppercased — matching the existing `_BatchCard` display pattern on the dashboard.

### Photo upload

Photos are fire-and-forget (see Open Question 4). The form allows the donor to select a photo; the file path is held in local state during the session. On submit, `StorageService.uploadBatchPhoto` is called for each item that has a photo. The `Batch` is written to Firestore first (with `photoUrl: null`). A follow-up `updateBatchPhotoUrl` call patches the document once each upload completes. The UI does not block submission on photo completion.

---

## Alternatives Considered

### Option A — Embedded items array (recommended)

Add `List<BatchItem>` to `Batch` and `BatchModel`. Summaries (`description`, `weightKg`, `portions`) become computed from the items list. Firestore stores items as an array field on the batch document.

**Upside:** Single document read/write per batch — no extra Firestore queries. The existing `watchActiveBatchesForDonor` stream and `DonorRepositoryImpl` mappers require no structural change (only the mapper gains `items` deserialization). The dashboard's `_BatchCard` subtitle uses `batch.portions` and `batch.weightKg`, which remain correct because they are now computed from the items array. Hive serialization is unchanged in shape — the JSON for the batch document gains an `items` array field. Freezed codegen handles the nested list cleanly with a custom `BatchItemModel` that mirrors `BatchItem`. Schema is fully readable in a single Firestore document panel — useful for donor support.

**Downside:** The `Batch` entity and `BatchModel` must change — this is a breaking change to the existing mapper in `DonorRepositoryImpl`. Any code that constructs a `Batch` directly (there is currently only one callsite: the form on submit) must be updated. If the items list grows very large (100+ items), the document size approaches Firestore's 1 MB limit. An item-level photo cannot be queried independently without reading the parent batch document.

**Effort:** Medium — new `BatchItem` entity, `BatchItemModel`, Freezed codegen, mapper update, and three screens.

### Option B — Keep single-item model, one document per item

Each "Add to Batch" press writes one `Batch` document. "Submit Batch" is a logical grouping operation: all documents share a `batchGroupId` field added to `Batch`. The Batch Summary shows all documents in the group. `CreateBatchUsecase` is called once per item; submit calls it in a `WriteBatch` (Firestore transaction).

**Upside:** Zero schema change to `Batch` or `BatchModel`. Backward compatible with all existing code. Each item's lifecycle (`open → delivered`) can be tracked independently. No Freezed regeneration for `BatchItem`.

**Downside:** "Batch" as shown in the Figma is a collection of items under one submitted unit — treating each item as a fully independent batch document is semantically wrong and creates UX problems. The dashboard's `watchActiveBatchesForDonor` would return 3 separate cards for a single "batch" that the donor thinks of as one. The QR code / batch number shown on the summary screen becomes ambiguous — which document does it belong to? The `batchGroupId` field is a denormalization that is not in the existing schema; adding it is still a schema change, just a smaller one. Driver and beneficiary assignment would need to be replicated across all documents in the group. Impact metrics aggregation by Cloud Function becomes more complex.

**Rejected:** The semantic model is wrong — one submission in the Figma is one batch with N items, not N separate batches. The dashboard UX breaks without additional filter/grouping logic that does not exist. The coordination overhead on the driver and metrics side outweighs the short-term simplicity of no schema change.

### Option C — Subcollection (`batches/{id}/items/{itemId}`)

Each `BatchItem` is a Firestore document at `batches/{batchId}/items/{itemId}`. The parent `batches/{batchId}` document holds the header fields; items are a subcollection.

**Upside:** Most normalized. Each item can be queried, updated, or deleted independently. No document-size concern for large batches. Clean separation of concerns in Firestore.

**Downside:** Every batch read requires two queries: one for the parent document and one `getDocs` on the items subcollection. The existing `watchActiveBatchesForDonor` stream returns `List<BatchModel>` from a single collection query — it would need to become an async fan-out (one `flatMap` per batch document to fetch its items subcollection). This breaks the stream contract and the Hive write-through cache, which currently stores the entire batch as a single JSON blob. The `DonorRepositoryImpl` would need a fundamentally different read path. Firestore's offline cache handles subcollection reads less predictably than top-level collection reads. Cold-start latency doubles (two round trips). Effort is high, and the gain (item-level queryability) is not required by any current feature or acceptance criterion.

**Rejected:** Breaks `watchActiveBatchesForDonor`, the Hive cache contract, and doubles read latency — all for a normalization benefit that no current feature requires. Reversal cost if chosen would be high (subcollection migration is destructive).

---

## Open Questions

All questions resolved 2026-05-23:

1. **Batch number generation.** ✅ **Resolved:** First 4 hex characters of the UUID, uppercased — matches the existing `_BatchCard` display pattern. No additional logic required.

2. **Beneficiary/destination assignment scope.** ✅ **Resolved:** In scope. Data source is a Firestore `beneficiaries` collection. `DonorRepository` gains a `getBeneficiaries()` method returning `Stream<List<Beneficiary>>`. The `Batch.beneficiaryId` field is set at submission time from the dropdown selection.

3. **Food category taxonomy.** ✅ **Resolved:** Hardcoded enum — offline-safe, no extra query. Initial values derived from Figma examples: `Bakery`, `Produce`, `Dairy`, `Meat`, `Beverages`, `Other`. The `BatchItem.category` field type is `FoodCategory` (enum).

4. **Photo upload blocking behavior.** ✅ **Resolved:** Fire-and-forget. The batch document is written to Firestore first with `photoUrl: null`; a follow-up patch updates the URL after each upload completes. Submission does not block on photo upload.

5. **Barcode-to-product-name resolution.** ✅ **Resolved:** Raw barcode string pre-fills the Product Name field; the donor edits it to the actual product name. No external API or lookup required.

---

## Acceptance Criteria

The following criteria are specific and testable. They feed directly into SPEC-0003 and the QA test matrix.

**Scanner screen**

- The scanner screen opens with a live camera viewfinder and a visible green reticle when navigated to via `/donor/log`.
- A successful barcode scan dismisses the scanner and navigates to the form screen with the `productName` field pre-filled with the scanned value.
- Tapping "Enter Manually" navigates to the form screen with an empty `productName` field.
- Camera permission denial shows a user-facing error message, not an unhandled exception.

**Form screen — field validation**

- "Add to Batch" is disabled (or shows inline errors) if any required field is empty: Product Name, Category, Quantity (kg), Expiry Time.
- Quantity must be a positive number greater than zero; non-numeric input is rejected inline.
- Expiry Time must be in the future; a past time is rejected with an inline error.
- All validation fires on "Add to Batch" tap — not on field blur.

**Form screen — photo upload**

- The photo upload area accepts an image from the device gallery.
- Photo upload is fire-and-forget: tapping "Add to Batch" does not wait for the upload to complete before navigating to the summary screen.
- If no photo is selected, the field is left empty without error.

**Batch summary screen**

- Each added item appears in the summary list with: category icon, product name, weight (kg), expiry time chip, and a delete button.
- Tapping the delete button removes that item from the list.
- The stats bar at the bottom shows the correct total item count and total weight kg, updated immediately when an item is added or deleted.
- "Add Another Item" navigates back to the scanner screen without losing previously added items.
- "Submit Batch" is disabled when the items list is empty.

**Submission**

- Tapping "Submit Batch" calls `CreateBatchUsecase` exactly once with a `Batch` whose `items` list matches the items shown in the summary.
- The submitted `Batch` has `status: BatchStatus.open`, a client-generated UUID `id`, and `qrCode` set to `'saveameal://batch/<id>'`.
- On successful Firestore write, the screen navigates to `/donor` and the new batch appears in the dashboard's active batch list within five seconds.
- On Firestore write failure, an error snackbar is shown and the donor remains on the summary screen (no data is lost).

**Architecture constraints**

- `BatchItem` entity contains zero Flutter or Firebase imports.
- `Batch` entity computed getters (`weightKg`, `portions`, `description`) are pure Dart — no framework logic.
- `LogSurplusFormScreen`, `ScannerScreen`, and `BatchSummaryScreen` access data exclusively through Riverpod providers — no direct Firestore, Hive, or Storage calls in widgets.
- The accumulated `List<BatchItem>` session state lives in a `StateNotifierProvider` scoped to the log-batch sub-graph — it is disposed when the donor navigates away from the flow.
- All item lists in the summary screen use `ListView.builder` — no unbounded `ListView`.
- Every new screen has a corresponding widget test.
