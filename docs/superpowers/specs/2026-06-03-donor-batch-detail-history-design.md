# Design: Donor Batch Detail + Donation History

**Date:** 2026-06-03  
**Branch:** `feature/donor-batch-detail-history`  
**Author:** KimTaeman  
**Status:** APPROVED (updated to match Figma reference)  
**Reference designs:** `Donation History (5 per page).png`, `Batch Details.png`

---

## Overview

Two new donor screens deferred as stubs in SPEC-0002:

1. **Donation History** (`/donor/batches`) — searchable, filterable list of all batches (5 per page with pagination).
2. **Batch Detail** (`/donor/batch/:batchId`) — summary cards, inventory breakdown, driver info, and pickup address.

---

## Data Model Changes

### `Batch` entity — `domain/entities/batch.dart`

One new optional field needed to surface the driver's display name (already on `BatchModel`):

```dart
final String? volunteerName;
```

`BatchModel` already has `volunteerName` — only the entity and `_toBatch` mapper need updating. No schema changes required.

---

## Repository Interface

Two new methods added to `DonorRepository`:

```dart
/// All batches for the donor, ordered by createdAt descending. No status filter.
Stream<List<Batch>> watchAllBatches(String donorId);

/// Single batch by ID as a live Firestore snapshot stream.
Stream<Batch> watchBatchById(String batchId);
```

No Hive caching. History is a secondary screen; offline seeding is not critical.

**Firestore queries:**
- `watchAllBatches` — `batches` collection, `where('donorId', isEqualTo: donorId)`. Client-side sort + filter.
- `watchBatchById` — `batches/{batchId}` document snapshot stream. `FirestoreService.watchBatch` already exists.

---

## Use Cases

- `WatchAllBatchesUsecase` — `call(String donorId)` → `Stream<List<Batch>>`
- `WatchBatchByIdUsecase` — `call(String batchId)` → `Stream<Batch>`

Files:
- `domain/usecases/watch_all_batches_usecase.dart`
- `domain/usecases/watch_batch_by_id_usecase.dart`

---

## Riverpod Providers

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

---

## Donation History Screen

**File:** `presentation/screens/donor_history_screen.dart`  
**Route:** `/donor/batches`

### Layout

```
Scaffold
  appBar: AppBar(
    leading: back arrow,
    title: 'Donation History' (bold, cs.primary),
    actions: [IconButton(Icons.notifications_outlined) → /notifications]
  )
  backgroundColor: cs.surface
  floatingActionButton: FAB(Icons.add) → context.push('/donor/log')
  body: SafeArea
    Column
      ─── Search bar         ← rounded TextField, "Search batch ID or date..."
      ─── Filter chips row   ← All | Completed | In Progress
      ─── "Recent Batches" header row with "N Total" count
      ─── Expanded → ListView.builder of _BatchHistoryCard (5 per page)
      ─── Pagination row     ← < [1] 2 3 >
  bottomNavigationBar: DonorBottomNav(currentIndex: 2)
```

### State (local — `ConsumerStatefulWidget`)
- `_filter`: `_HistoryFilter.all | completed | inProgress`
- `_searchQuery`: `String`
- `_currentPage`: `int` (0-indexed)
- `_pageSize = 5`

### Filter logic

| Chip | Included statuses |
|------|-------------------|
| All | all |
| Completed | `delivered`, `closed` |
| In Progress | `open`, `claimed`, `pickedUp` |

Search: case-insensitive match on first 4 chars of batch ID or formatted date string.  
Pagination: client-side slice `filteredBatches.sublist(start, end)`.  
Changing filter or search resets `_currentPage` to 0.

### `_BatchHistoryCard`

```
InkWell (onTap → /donor/batch/${batch.id})
  Card (white, elevation: 1, rounded: 12)
    Row
      ─── Container(w: 4, color: accentColor)     ← left status accent
      ─── SizedBox(8)
      ─── CircleAvatar(r: 24, bg: circleBg)        ← category icon of first item (or inventory icon)
          + Icon(categoryIcon, color: circleIconColor)
      ─── SizedBox(12)
      ─── Expanded
            Row: Text('#${id.substring(0,4).toUpperCase()}', bold titleMedium)
                 [+ Chip('PRIORITY') if batch has items.length > 5]  ← omit priority logic for now
            Text(formattedDateTime, bodySmall, grey)
            Row: Icon(Icons.scale_outlined, 14) + Text('${weightKg}kg', bodySmall)
                 SizedBox(8)
                 Icon(Icons.inventory_2_outlined, 14) + Text('${portions} items', bodySmall)
      ─── SizedBox(8)
      ─── _StatusBadge(status)
      ─── SizedBox(8)
```

**Accent color** (`accentColor`):
- `delivered`, `closed` → `cs.primary`
- `open`, `claimed`, `pickedUp` → `ac.warning`
- `cancelled` → `ac.danger`

**Circle bg** (`circleBg`): same as accent color with `withValues(alpha: 0.15)`.

**`_StatusBadge`:**
- Done states (`delivered`, `closed`): `Icon(Icons.check_circle, color: cs.primary)` + `Text('DONE', cs.primary, labelSmall)`
- Active states (`open`, `claimed`, `pickedUp`): `Icon(Icons.sync, color: ac.warning)` + `Text('ACTIVE', ac.warning, labelSmall)`

**Date format:** `'${monthName} ${day}, ${year} · ${h}:${mm} ${AM/PM}'`

### Pagination row

```
Row(mainAxisAlignment: center)
  IconButton(Icons.chevron_left)  ← disabled on page 0
  [page buttons: OutlinedButton or FilledButton per page index]
  IconButton(Icons.chevron_right) ← disabled on last page
```

Show at most 3 page buttons. Selected page: `FilledButton`. Others: `OutlinedButton`.

### Empty + error states

- Empty (after filter): `Icon(Icons.volunteer_activism, 64) + Text('No donations yet')`
- Loading: `CircularProgressIndicator` centered
- Error: `Icon(Icons.cloud_off) + Text('Could not load donations') + TextButton('Retry')`

---

## Batch Detail Screen

**File:** `presentation/screens/batch_detail_screen.dart`  
**Route:** `/donor/batch/:batchId`

### Layout

```
Scaffold
  appBar: AppBar(
    leading: back arrow,
    title: 'Batch Details' (bold, cs.primary),
    actions: [
      IconButton(Icons.notifications_outlined) → /notifications,
      if batch.status == open: IconButton(Icons.qr_code) → /donor/batch/:id/qr
    ]
  )
  body: AsyncValue on batchByIdProvider(batchId)
    Loading → CircularProgressIndicator centered
    Error   → Icon(cloud_off) + 'Could not load batch'
    Data    →
      SingleChildScrollView
        Column (padding: horizontal Spacing.md, vertical Spacing.md)
          ─── _BatchChip(batchId)              ← amber pill "Batch #XXXX"
          ─── SizedBox(Spacing.sm)
          ─── Text(statusHeading, headlineMedium, bold)
          ─── SizedBox(Spacing.xs)
          ─── Row: Icon(Icons.calendar_today, 14) + Text(formattedDate)
          ─── SizedBox(Spacing.sm)
          ─── _StatusPill(status)              ← full-width green pill "✓ Status: [label]"
          ─── SizedBox(Spacing.md)
          ─── Row: [_SummaryCard(weight)] [SizedBox(8)] [_SummaryCard(items)]
          ─── SizedBox(Spacing.md)
          ─── Text('Inventory Breakdown', titleMedium, bold)
          ─── SizedBox(Spacing.sm)
          ─── ListView.builder(shrinkWrap, items) of _InventoryItemCard
          ─── SizedBox(Spacing.md)
          ─── if batch.volunteerName != null: _DriverCard(volunteerName)
          ─── SizedBox(Spacing.md)
          ─── _AddressCard(pickupAddress)
          ─── SizedBox(Spacing.md)
```

### Sub-widgets

**`_BatchChip`:** `Chip` with `labelStyle` in `cs.onTertiaryContainer`, `backgroundColor: cs.tertiaryContainer`. Label: `'Batch #${id.substring(0,4).toUpperCase()}'`.

**`statusHeading`** mapping:
| Status | Heading |
|--------|---------|
| `open` | `'Waiting for Pickup'` |
| `claimed` | `'Driver Assigned'` |
| `pickedUp` | `'Collected Successfully'` |
| `delivered` | `'Delivered Successfully'` |
| `closed` | `'Completed'` |
| `cancelled` | `'Cancelled'` |

**`_StatusPill`:** `Container` full-width, `cs.primary` background, `BorderRadius.circular(24)`, padding `vertical: 12`. Row with `Icon(Icons.check_circle, white)` + `Text('Status: ${statusLabel}', white, bold)`.

**`_SummaryCard`:** `Expanded` `Card`. `Column`: `CircleAvatar(bg: cs.primaryContainer)` with icon + `Text(label, labelSmall, grey)` + `Text(value, headlineSmall, bold)`.
- Weight card: `Icon(Icons.scale_outlined)`, label `'Total Weight'`, value `'${weightKg.toStringAsFixed(1)} kg'`
- Items card: `Icon(Icons.inventory_2_outlined)`, label `'Total Items'`, value `'${portions} Products'`

**`_InventoryItemCard`:** `Card` with `Column` children:
- `Container(h: 4, color: cs.primary)` — green top accent
- `Padding` with `Row`:
  - `CircleAvatar(bg: cs.primaryContainer, radius: 20)` with category icon
  - `SizedBox(12)`
  - `Expanded Column`: `Text(item.name, bold)` + `Text(categoryDisplayName, bodySmall, grey)`
  - `Chip(label: '${item.weightKg.toStringAsFixed(1)}kg')`

Category display names: `bakery → 'Bakery'`, `produce → 'Produce'`, `dairy → 'Dairy'`, `meat → 'Meat'`, `beverages → 'Beverages'`, `other → 'Other'`.

**`_DriverCard`:** `Card` with dashed border (use `DashedBorderPainter` from `SafetyVerificationScreen` pattern or `Container` with `BoxDecoration(border: Border.all(style: BorderStyle.none))` — simplify to solid border with low opacity). `Row`: `CircleAvatar(child: Text(initials))` + `Column('Collected by', Text('$name (Driver)', bold))`.

Driver initials: first letter of `volunteerName`, uppercase. Avatar bg: `cs.tertiaryContainer`.

**`_AddressCard`:** `Container` with `BoxDecoration(color: Color(0xFF1B5E20), borderRadius: 12)`. `Row`: `Icon(Icons.location_on, white)` + `Expanded(Text(pickupAddress, white))` + `Icon(Icons.chevron_right, white)`. Height: 80px approx.

---

## Router Changes

Replace flat `batch/:batchId/qr` with nested structure:

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
GoRoute(
  path: 'batches',
  builder: (context, state) => const DonorHistoryScreen(),
),
```

`_BatchCard` on dashboard: add `onTap: () => context.push('/donor/batch/${batch.id}')`. Remove QR `IconButton` from card trailing (QR lives in `BatchDetailScreen` AppBar).

---

## File Map

| Action | Path |
|--------|------|
| **Modify** | `domain/entities/batch.dart` — add `volunteerName` |
| **Modify** | `data/repositories/donor_repository_impl.dart` — map `volunteerName` in `_toBatch`/`_fromBatch` |
| **Modify** | `services/firestore_service.dart` — add `watchAllBatchesForDonor` |
| **Modify** | `data/datasources/donor_remote_datasource.dart` — add `watchAllBatches` + `watchBatchById` |
| **Modify** | `domain/repositories/donor_repository.dart` — add two signatures |
| **Create** | `domain/usecases/watch_all_batches_usecase.dart` |
| **Create** | `domain/usecases/watch_batch_by_id_usecase.dart` |
| **Modify** | `presentation/providers/donor_provider.dart` — add 4 providers |
| **Create** | `presentation/screens/donor_history_screen.dart` |
| **Create** | `presentation/screens/batch_detail_screen.dart` |
| **Modify** | `presentation/screens/donor_dashboard_screen.dart` — make `_BatchCard` tappable |
| **Modify** | `app/router.dart` — nest QR; replace batches stub; add imports |

---

## Out of Scope

- Sequential batch numbers (shows first 4 chars of UUID — Figma shows sequential ints we don't have)
- Driver photo (uses initials `CircleAvatar` — Figma shows a photo)
- Real map widget (shows styled address card — Figma shows Google Maps view; no coordinates available from string address)
- Actual dashed border on driver card (solid border used for simplicity)
- PRIORITY badge logic (no priority field in data model)
- Infinite scroll (pagination is client-side slice of all-loaded list)
