---
title: "0003: Log Surplus Batch — multi-item entry flow"
description: "Full implementation of the 3-screen donor log-batch flow (Scanner → Form → Summary), BatchItem domain model, and all supporting layers."
---

# SPEC-0003: Log Surplus Batch — multi-item entry flow

**Status:** APPROVED
**Author:** Kim Taeman
**Date:** 2026-05-23
**Proposal:** [PROP-0003](../tech-proposals/0003-log-batch.md)
**Approved by:** (fill in when approved)

---

## Overview

Replaces the `LogBatchScreen` stub with a complete 3-screen flow: a barcode scanner (`ScannerScreen`), an item entry form (`LogSurplusFormScreen`), and a batch summary (`BatchSummaryScreen`). A donor scans or manually enters one food item at a time, accumulates items in session state, and submits the whole batch in one Firestore write. The data model is migrated from single-item (`description`, `weightKg`, `portions` as stored fields) to multi-item (`List<BatchItem>` embedded on the batch document) with backward-compatible computed getters so the existing dashboard and QR screens require no changes.

---

## Architecture

```
ScannerScreen
    │  (barcode string via StateProvider)
    ▼
LogSurplusFormScreen  ──append──▶  BatchSessionNotifier
    │                                  List<BatchItem>
    ▼
BatchSummaryScreen ──submit──▶ CreateBatchUsecase ──▶ DonorRepository ──▶ FirestoreService
                   └─fire-and-forget──▶ StorageService.uploadBatchPhoto
```

---

## File map

| Action | Path | Responsibility |
|---|---|---|
| **Create** | `lib/features/donor/domain/entities/batch_item.dart` | `BatchItem` value object — pure Dart |
| **Create** | `lib/features/donor/domain/entities/food_category.dart` | `FoodCategory` enum — pure Dart |
| **Create** | `lib/features/donor/domain/entities/beneficiary.dart` | `Beneficiary` entity — pure Dart |
| **Modify** | `lib/features/donor/domain/entities/batch.dart` | Add `items`, computed getters; remove stored `description`/`weightKg`/`portions` |
| **Modify** | `lib/features/donor/domain/repositories/donor_repository.dart` | Add `getBeneficiaries()` |
| **Create** | `lib/core/models/batch_item_model.dart` | Freezed model for `BatchItem` |
| **Modify** | `lib/core/models/batch_model.dart` | Add `items` field; computed fields become JSON-serialized from items |
| **Modify** | `lib/features/donor/data/datasources/donor_remote_datasource.dart` | Add `getBeneficiaries()` |
| **Modify** | `lib/features/donor/data/repositories/donor_repository_impl.dart` | Update mappers; add `getBeneficiaries()` impl |
| **Create** | `lib/features/donor/presentation/providers/batch_session_provider.dart` | `BatchSessionNotifier` + `scannedBarcodeProvider` |
| **Modify** | `lib/features/donor/presentation/providers/donor_provider.dart` | Add `beneficiariesProvider` |
| **Modify** | `lib/features/donor/presentation/screens/log_batch_screen.dart` | Replace stub — redirect to scanner |
| **Create** | `lib/features/donor/presentation/screens/scanner_screen.dart` | Barcode scanner screen |
| **Create** | `lib/features/donor/presentation/screens/log_surplus_form_screen.dart` | Item entry form |
| **Create** | `lib/features/donor/presentation/screens/batch_summary_screen.dart` | Accumulated items + submit |
| **Modify** | `lib/app/router.dart` | Add `scanner`, `log/form`, `log/summary` sub-routes under `/donor/log` |
| **Modify** | `lib/services/storage_service.dart` | Implement `uploadBatchPhoto` |

---

## API contracts

### Domain entities

```dart
// lib/features/donor/domain/entities/food_category.dart
enum FoodCategory { bakery, produce, dairy, meat, beverages, other }

// lib/features/donor/domain/entities/beneficiary.dart
class Beneficiary {
  const Beneficiary({required this.id, required this.name, this.address});
  final String id;
  final String name;
  final String? address;
}

// lib/features/donor/domain/entities/batch_item.dart
class BatchItem {
  const BatchItem({
    required this.name,
    required this.category,
    required this.weightKg,
    required this.expiryTime,
    this.photoUrl,
    this.localPhotoPath,
  });

  final String name;
  final FoodCategory category;
  final double weightKg;
  final DateTime expiryTime;
  final String? photoUrl;         // null until upload completes
  final String? localPhotoPath;   // transient — not serialized to Firestore
}
```

### Modified Batch entity

```dart
// lib/features/donor/domain/entities/batch.dart  (modified)
class Batch {
  const Batch({
    required this.id,
    required this.donorId,
    required this.items,           // NEW — replaces stored description/weightKg/portions
    required this.pickupAddress,
    required this.status,
    this.driverId,
    this.beneficiaryId,
    this.photoUrl,                 // kept for backward compat (first item's photo)
    this.qrCode,
    this.rating,
    this.feedback,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String donorId;
  final List<BatchItem> items;
  final String pickupAddress;
  final BatchStatus status;
  final String? driverId;
  final String? beneficiaryId;
  final String? photoUrl;
  final String? qrCode;
  final int? rating;
  final String? feedback;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Computed from items — backward-compatible with dashboard _BatchCard
  double get weightKg => items.fold(0, (s, i) => s + i.weightKg);
  int get portions => items.length;
  String get description => items.map((i) => i.name).join(', ');
}
```

### Repository interface

```dart
// lib/features/donor/domain/repositories/donor_repository.dart  (added method)
abstract class DonorRepository {
  Stream<List<Batch>> watchActiveBatches(String donorId);
  Stream<DonorMetrics> watchMetrics(String donorId);
  Future<void> createBatch(Batch batch);
  Stream<List<Beneficiary>> getBeneficiaries();    // NEW
}
```

### Data models

```dart
// lib/core/models/batch_item_model.dart  (new Freezed)
@freezed
sealed class BatchItemModel with _$BatchItemModel {
  const factory BatchItemModel({
    required String name,
    required String category,     // FoodCategory.name string
    required double weightKg,
    required DateTime expiryTime,
    String? photoUrl,
  }) = _BatchItemModel;

  factory BatchItemModel.fromJson(Map<String, dynamic> json) =>
      _$BatchItemModelFromJson(json);
}

// lib/core/models/batch_model.dart  (modified — adds items, removes stored summaries)
@freezed
sealed class BatchModel with _$BatchModel {
  const factory BatchModel({
    required String id,
    required String donorId,
    @Default([]) List<BatchItemModel> items,   // NEW
    required String pickupAddress,
    required BatchStatus status,
    String? driverId,
    String? beneficiaryId,
    String? photoUrl,
    String? qrCode,
    int? rating,
    String? feedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _BatchModel;

  factory BatchModel.fromJson(Map<String, dynamic> json) =>
      _$BatchModelFromJson(json);
}
// Note: description, weightKg, portions are REMOVED as stored fields.
// They are computed in the domain Batch entity from the items list.
// The dashboard query and _BatchCard use batch.portions / batch.weightKg
// which now resolve through the computed getters — no dashboard changes needed.
```

### Session state

```dart
// lib/features/donor/presentation/providers/batch_session_provider.dart

// Holds the barcode string from the last successful scan.
// Reset to null when the donor exits the log-batch flow.
@riverpod
class ScannedBarcode extends _$ScannedBarcode {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

// Accumulates BatchItems for the current session.
// Disposed when the donor navigates away from the log-batch sub-graph.
@riverpod
class BatchSession extends _$BatchSession {
  @override
  List<BatchItem> build() => [];
  void add(BatchItem item) => state = [...state, item];
  void remove(int index) => state = [...state]..removeAt(index);
  void clear() => state = [];
}
```

### Providers (additions to donor_provider.dart)

```dart
@riverpod
Stream<List<Beneficiary>> beneficiaries(Ref ref) =>
    ref.watch(donorRepositoryProvider).getBeneficiaries();
```

### StorageService

```dart
// lib/services/storage_service.dart  (implement)
Future<String> uploadBatchPhoto(String batchId, String itemIndex, File photo) async {
  final ref = _storage
      .ref()
      .child('batches/$batchId/items/$itemIndex.jpg');
  await ref.putFile(photo);
  return ref.getDownloadURL();
}
```

---

## Screen layouts

### ScannerScreen (`/donor/log`)

- Full-screen `MobileScanner` viewfinder with dark overlay
- White title "Scan Product" centered at top with back arrow
- Subtitle "Center barcode in the frame to log surplus"
- Green corner reticle (4 L-shaped white corners drawn with CustomPaint, 40×40 px)
- "SCANNING..." label below reticle
- Bottom sheet (persistent, non-dismissible): "Barcode damaged? You can still log this item." + green pill "Enter Manually" button
- On decode: store barcode string in `scannedBarcodeProvider`, push to `/donor/log/form`
- On "Enter Manually": clear `scannedBarcodeProvider`, push to `/donor/log/form`
- Camera permission denied: replace viewfinder with error message + settings link

### LogSurplusFormScreen (`/donor/log/form`)

Fields (all full-width, stacked vertically, `Spacing.md` padding):

| Field | Widget | Validation |
|---|---|---|
| Product Name | `TextFormField` | Required; pre-filled from `scannedBarcodeProvider` if non-null |
| Category | `DropdownButtonFormField<FoodCategory>` | Required |
| Quantity (kg) | `TextFormField(keyboardType: decimal)` | Required; > 0 |
| Expiry Time | `TextFormField` + `showTimePicker` | Required; must be in the future |
| Assign Beneficiary | `DropdownButtonFormField<Beneficiary>` | Optional; populated from `beneficiariesProvider` |
| Photo | Dashed `InkWell` border → `ImagePicker.gallery` | Optional |

- "Add to Batch" green `FilledButton` at bottom, full-width
- Validation fires on "Add to Batch" tap only (not on field blur)
- On valid: append `BatchItem` to `batchSessionProvider`, push to `/donor/log/summary`

### BatchSummaryScreen (`/donor/log/summary`)

- App bar: "Batch Summary" title, back arrow
- `ListView.builder` of item cards:
  - Each card: thin green top accent line (4 px), `cs.surfaceContainerLow` background, `BorderRadius.circular(12)`
  - Leading: category icon (see icon map below)
  - Title: item name, bold
  - Subtitle: `${item.weightKg}kg`
  - Trailing: expiry chip (green `FilterChip` text "Expires in Xh" or "Expires tomorrow") + `IconButton(Icons.delete_outline)` → `batchSession.remove(index)`
- Stats bar (pinned at bottom above submit button): "X items  •  Y.Z kg total"
- "Add Another Item" `OutlinedButton` — navigates to `/donor/log` (scanner), keeps session state
- "Submit Batch #XXXX" `FilledButton` — disabled when items list is empty; XXXX = first 4 chars of UUID uppercased
- On submit:
  1. Build `Batch` from session state (UUID id, `status: BatchStatus.open`, `qrCode: 'saveameal://batch/<id>'`)
  2. Call `createBatchUsecase(batch)` — await
  3. For each item with `localPhotoPath != null`: `storageService.uploadBatchPhoto(...)` fire-and-forget (unawaited)
  4. Clear `batchSessionProvider`
  5. Navigate to `/donor`
  6. On Firestore error: show `SnackBar` with error message, remain on summary screen

**Category icon map** (all from `Icons.*`):
- `bakery` → `Icons.bakery_dining`
- `produce` → `Icons.eco`
- `dairy` → `Icons.egg_outlined`
- `meat` → `Icons.set_meal`
- `beverages` → `Icons.local_cafe_outlined`
- `other` → `Icons.category_outlined`

---

## Firestore schema

Existing `batches/{batchId}` document gains an `items` array field. The `description`, `weightKg`, and `portions` top-level fields are **removed** from new documents. Old documents (pre-migration) that still have those fields will be read correctly by `BatchModel.fromJson` because `items` defaults to `[]` — the dashboard will show "0 items • 0.0kg" for them.

```
batches/{batchId}
  id:           string
  donorId:      string
  pickupAddress: string
  status:       string   (BatchStatus enum name)
  items: [
    {
      name:       string
      category:   string   (FoodCategory enum name)
      weightKg:   number
      expiryTime: timestamp
      photoUrl:   string | null
    }
  ]
  driverId:      string | null
  beneficiaryId: string | null
  photoUrl:      string | null   (kept — first item's photo for backward compat)
  qrCode:        string | null
  rating:        number | null
  feedback:      string | null
  createdAt:     timestamp | null
  updatedAt:     timestamp | null
```

New `beneficiaries` collection (read-only from app):

```
beneficiaries/{beneficiaryId}
  id:      string
  name:    string
  address: string | null
```

---

## Router changes

```dart
GoRoute(
  path: '/donor/log',
  builder: (_, __) => const ScannerScreen(),
  routes: [
    GoRoute(
      path: 'form',
      builder: (_, __) => const LogSurplusFormScreen(),
    ),
    GoRoute(
      path: 'summary',
      builder: (_, __) => const BatchSummaryScreen(),
    ),
  ],
),
```

The existing `LogBatchScreen` stub is removed; `/donor/log` now maps directly to `ScannerScreen`.

---

## Test plan

| Test file | Covers |
|---|---|
| `test/unit/features/donor/domain/entities/batch_item_test.dart` | `BatchItem` construction; `Batch` computed getters (`weightKg`, `portions`, `description`) with multiple items |
| `test/unit/features/donor/presentation/providers/batch_session_test.dart` | `BatchSessionNotifier.add`, `remove`, `clear`; item count and totals after each operation |
| `test/widget/features/donor/presentation/screens/scanner_screen_test.dart` | Renders viewfinder stub; "Enter Manually" navigates to form; camera-denied shows error widget |
| `test/widget/features/donor/presentation/screens/log_surplus_form_screen_test.dart` | "Add to Batch" disabled until required fields filled; quantity rejects non-numeric; expiry rejects past time; valid submit appends item and navigates |
| `test/widget/features/donor/presentation/screens/batch_summary_screen_test.dart` | Items render from provider; delete removes item; stats bar updates; "Submit Batch" disabled on empty list; successful submit navigates to `/donor`; Firestore error shows SnackBar |

---

## Out of scope

- Driver-side batch claiming or status updates (separate feature)
- Offline queue for failed batch submissions (future enhancement)
- Push notification to donor on batch status change
- Editing a submitted batch
- `BatchQrScreen` redesign to match `QR Code Display.png` (separate card — note the design shows title "Pickup Code", subtitle "Show this to the store staff", a "BATCH SUMMARY" cream card with portions + "Valid today until [time]")
- Sequential batch counter (UUID prefix is sufficient for this sprint)

---

## Open questions

All questions resolved — see PROP-0003.
