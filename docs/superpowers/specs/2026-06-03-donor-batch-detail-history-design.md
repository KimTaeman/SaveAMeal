# Design: Donor Batch Detail + Donation History

**Date:** 2026-06-03  
**Branch:** `feature/donor-batch-detail-history`  
**Author:** KimTaeman  
**Status:** APPROVED

---

## Overview

Implements two new donor screens that were explicitly deferred as stubs in SPEC-0002:

1. **Donation History** (`/donor/batches`) — replaces the "All Batches" stub with a filterable list of all the donor's batches across all statuses.
2. **Batch Detail** (`/donor/batch/:batchId`) — new screen showing full batch information: item list, status timeline with per-status timestamps, driver info, and the QR button (moved from the dashboard card).

---

## Data Model Changes

### `Batch` entity — `domain/entities/batch.dart`

Four new optional timestamp fields:

```dart
final DateTime? claimedAt;
final DateTime? pickedUpAt;
final DateTime? deliveredAt;
final DateTime? closedAt;
```

Existing `createdAt` and `updatedAt` fields are unchanged. All four new fields are nullable — old documents that lack them deserialize to `null`; the timeline shows "—" for missing entries.

### `BatchModel` — `core/models/batch_model.dart`

Same four fields added as `DateTime?` with `@JsonKey` Freezed annotations. Cloud Functions must write these on status transitions (e.g., when setting `status = 'claimed'`, also write `claimedAt = FieldValue.serverTimestamp()`). Flutter reads them; it never writes them.

---

## Repository Interface

Two new methods added to `DonorRepository` (`domain/repositories/donor_repository.dart`):

```dart
/// All batches for the donor, ordered by createdAt descending. No status filter.
Stream<List<Batch>> watchAllBatches(String donorId);

/// Single batch by ID as a live Firestore snapshot stream.
Stream<Batch> watchBatchById(String batchId);
```

No Hive caching for either method. The history list is a secondary screen; offline seeding is not critical. The existing `watchActiveBatches` Hive cache is unaffected.

**Firestore queries:**
- `watchAllBatches` — `batches` collection, `where('donorId', isEqualTo: donorId)`, `orderBy('createdAt', descending: true)`. Status filtering is client-side.
- `watchBatchById` — `batches/{batchId}` document snapshot stream.

---

## Use Cases

Two new use cases (pure Dart, zero Flutter imports):

- `WatchAllBatchesUsecase` — `call(String donorId)` → `Stream<List<Batch>>`
- `WatchBatchByIdUsecase` — `call(String batchId)` → `Stream<Batch>`

Files:
- `domain/usecases/watch_all_batches_usecase.dart`
- `domain/usecases/watch_batch_by_id_usecase.dart`

---

## Riverpod Providers

Added to `presentation/providers/donor_provider.dart`:

```dart
@riverpod
WatchAllBatchesUsecase watchAllBatchesUsecase(Ref ref) =>
    WatchAllBatchesUsecase(ref.watch(donorRepositoryProvider));

@riverpod
WatchBatchByIdUsecase watchBatchByIdUsecase(Ref ref) =>
    WatchBatchByIdUsecase(ref.watch(donorRepositoryProvider));

@riverpod
Stream<List<Batch>> allBatches(Ref ref, String donorId) =>
    ref.watch(watchAllBatchesUsecaseProvider).call(donorId);

@riverpod
Stream<Batch> batchById(Ref ref, String batchId) =>
    ref.watch(watchBatchByIdUsecaseProvider).call(batchId);
```

All existing providers (`activeBatchesProvider`, `donorMetricsProvider`, etc.) are unchanged.

---

## Donation History Screen

**File:** `presentation/screens/donor_history_screen.dart`  
**Route:** `/donor/batches`

### Layout

```
Scaffold
  appBar: AppBar(title: 'Donation History', centerTitle: false)
  backgroundColor: cs.surface
  body: SafeArea
    Column
      ─── _StatusFilterChips         ← horizontal scroll row
      ─── Expanded
            AsyncValue on allBatchesProvider(donorId)
              Loading → CircularProgressIndicator centered
              Error   → cloud_off icon + message + Retry button
              Data    → filtered ListView.builder of _HistoryBatchCard
                        (empty state: volunteer_activism icon + 'No donations yet')
  bottomNavigationBar: DonorBottomNav(currentIndex: 2)
```

### `_StatusFilterChips`

Three `FilterChip`s in a horizontally scrollable `SingleChildScrollView`:

| Chip | Included statuses |
|------|-------------------|
| All | all |
| Active | `open`, `claimed`, `pickedUp` |
| Completed | `delivered`, `closed` |

Selected chip: `cs.primary` fill. Unselected: outlined. State held locally with `useState`/`StatefulWidget`.

### `_HistoryBatchCard`

Same visual as the dashboard `_BatchCard` (thin green 4px top accent, `cs.surfaceContainerLow` background, `BorderRadius.circular(12)`, `ListTile` with batch short ID, item count, weight, status label, date). **No QR button** — tapping the card navigates to `/donor/batch/${batch.id}`.

### Error handling

Error state renders `Icon(Icons.cloud_off)` + `Text('Could not load donations')` + `TextButton('Retry')` that calls `ref.invalidate(allBatchesProvider(donorId))`. AppBar and BottomNav remain visible.

---

## Batch Detail Screen

**File:** `presentation/screens/batch_detail_screen.dart`  
**Route:** `/donor/batch/:batchId`

### Layout

```
Scaffold
  appBar: AppBar(
    title: 'Batch #${batchId.substring(0,8).toUpperCase()}',
    centerTitle: false,
    actions: [IconButton(Icons.qr_code) — only when batch.status == open]
  )
  backgroundColor: cs.surface
  body: AsyncValue on batchByIdProvider(batchId)
    Loading → CircularProgressIndicator centered
    Error   → cloud_off icon + message centered
    Data    →
      SingleChildScrollView
        Column (Spacing.md padding horizontal)
          ─── _StatusBanner(status)
          ─── _ItemsSection(items)
          ─── _TimelineSection(batch)
          ─── _DriverSection(batch)   ← only when driverId != null
```

### `_StatusBanner`

Full-width `Container` with `BorderRadius.circular(12)`, color-coded:

| Status | Background |
|--------|-----------|
| `open` | `cs.primaryContainer` |
| `claimed`, `pickedUp` | `ac.warning` at low opacity |
| `delivered`, `closed` | `ac.success` at low opacity |

Centered bold status label using `_statusLabel()` helper (same mapping as dashboard).

### `_ItemsSection`

`Card` with title row `"Items (${items.length})"`. `ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` of rows:

- Leading: category icon (same icon map as `BatchSummaryScreen`)
- Title: item name (bold)
- Subtitle: `${item.weightKg} kg`
- Trailing: expiry chip — green `Chip` with "Expires [date]" or "Expired" in red if past

Empty items list shows `Text('No item data available')` centered.

### `_TimelineSection`

`Card` with title `"Timeline"`. Four fixed rows in order:

| Step | Timestamp field |
|------|----------------|
| Created | `batch.createdAt` |
| Claimed | `batch.claimedAt` |
| Picked Up | `batch.pickedUpAt` |
| Delivered | `batch.deliveredAt` |

Each row: vertical line connector (grey) + circular dot (filled `cs.primary` if timestamp non-null, outlined grey if null) + `Text(label)` + `Text(formattedTimestamp or '—')`.

### `_DriverSection`

`Card` with title `"Driver"`. Shown only when `batch.driverId != null`. Displays `Text('Driver ID: ${batch.driverId}')`. Driver name/profile lookup is out of scope.

### Navigation

QR `IconButton` in AppBar (only on `open` batches): `context.push('/donor/batch/${batch.id}/qr')`.

### Error handling

Error state renders `Icon(Icons.cloud_off)` + `Text('Could not load batch')` centered. AppBar remains visible (shows batchId in title).

---

## Router Changes

**Existing `batch/:batchId/qr` flat route replaced** with a nested structure:
```dart
GoRoute(
  path: 'batch/:batchId',
  builder: (context, state) => BatchDetailScreen(
    batchId: state.pathParameters['batchId']!,
  ),
  routes: [
    GoRoute(
      path: 'qr',
      builder: (context, state) => BatchQrScreen(
        batchId: state.pathParameters['batchId']!,
      ),
    ),
  ],
),
```

**`/donor/batches` stub replaced:**
```dart
GoRoute(
  path: 'batches',
  builder: (context, state) => const DonorHistoryScreen(),
),
```

**`_BatchCard` on dashboard** — `onTap` added: `context.push('/donor/batch/${batch.id}')`. QR `IconButton` removed from card trailing (it lives in `BatchDetailScreen` AppBar now).

---

## Dashboard Card Change

`_BatchCard` in `donor_dashboard_screen.dart`:
- Add `onTap: () => context.push('/donor/batch/${batch.id}')` to the `Card`
- Remove the `open`-status QR `IconButton` from `trailing`
- All other card content unchanged

---

## File Map

| Action | Path |
|--------|------|
| **Modify** | `domain/entities/batch.dart` — add 4 timestamp fields |
| **Modify** | `core/models/batch_model.dart` — add 4 timestamp fields (Freezed) |
| **Modify** | `domain/repositories/donor_repository.dart` — add 2 method signatures |
| **Create** | `domain/usecases/watch_all_batches_usecase.dart` |
| **Create** | `domain/usecases/watch_batch_by_id_usecase.dart` |
| **Modify** | `data/datasources/donor_remote_datasource.dart` — add 2 method signatures + impls |
| **Modify** | `data/repositories/donor_repository_impl.dart` — implement 2 new methods |
| **Modify** | `presentation/providers/donor_provider.dart` — add 4 providers |
| **Create** | `presentation/screens/donor_history_screen.dart` |
| **Create** | `presentation/screens/batch_detail_screen.dart` |
| **Modify** | `presentation/screens/donor_dashboard_screen.dart` — update `_BatchCard` |
| **Modify** | `app/router.dart` — replace flat `batch/:batchId/qr` route with nested `batch/:batchId` + `qr` child; replace batches stub |

---

## Test Plan

| File | Covers |
|------|--------|
| `test/unit/donor/domain/usecases/watch_all_batches_usecase_test.dart` | Delegates to repository; stream emits mock list |
| `test/unit/donor/domain/usecases/watch_batch_by_id_usecase_test.dart` | Delegates to repository; stream emits mock batch |
| `test/widget/donor/presentation/screens/donor_history_screen_test.dart` | Loading state; All chip shows all batches; Active chip filters to open/claimed/pickedUp; Completed chip filters to delivered/closed; empty state; card tap pushes `/donor/batch/:id`; error state shows retry |
| `test/widget/donor/presentation/screens/batch_detail_screen_test.dart` | Loading state; status banner renders for each status; items section shows N items; timeline shows timestamps and "—" for nulls; driver section hidden when driverId null; QR button visible only on open batch; QR button navigates to QR route; error state |

---

## Out of Scope

- Driver name/profile lookup on the detail screen (shows driverId only)
- Hive caching for history or detail streams
- Pagination or infinite scroll on the history list
- Editing or cancelling a submitted batch
- Cloud Function implementation for writing the four new timestamps (assumed handled by backend team)
- Adding `closedAt` to the timeline (delivery is the terminal user-visible state)
