# Donor Batch Detail + Donation History Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement `DonorHistoryScreen` (`/donor/batches`) — searchable, paginated batch list with filter chips — and `BatchDetailScreen` (`/donor/batch/:batchId`) — summary cards, inventory breakdown, driver info, pickup address — matching the Figma reference designs.

**Architecture:** Extend `DonorRepository` with `watchAllBatches` and `watchBatchById`; add `volunteerName` to `Batch` entity (already on `BatchModel`); both screens are `ConsumerStatefulWidget`s reading from new Riverpod family providers.

**Tech Stack:** Flutter, Riverpod (riverpod_annotation codegen), GoRouter, Firestore (`cloud_firestore`)

**Figma references:** `Donation History (5 per page).png`, `Batch Details.png`

---

## File Map

| Action | Path |
|--------|------|
| **Modify** | `apps/mobile/lib/features/donor/domain/entities/batch.dart` |
| **Modify** | `apps/mobile/lib/features/donor/data/repositories/donor_repository_impl.dart` |
| **Modify** | `apps/mobile/lib/services/firestore_service.dart` |
| **Modify** | `apps/mobile/lib/features/donor/data/datasources/donor_remote_datasource.dart` |
| **Modify** | `apps/mobile/lib/features/donor/domain/repositories/donor_repository.dart` |
| **Create** | `apps/mobile/lib/features/donor/domain/usecases/watch_all_batches_usecase.dart` |
| **Create** | `apps/mobile/lib/features/donor/domain/usecases/watch_batch_by_id_usecase.dart` |
| **Modify** | `apps/mobile/lib/features/donor/presentation/providers/donor_provider.dart` |
| **Create** | `apps/mobile/lib/features/donor/presentation/screens/donor_history_screen.dart` |
| **Create** | `apps/mobile/lib/features/donor/presentation/screens/batch_detail_screen.dart` |
| **Modify** | `apps/mobile/lib/features/donor/presentation/screens/donor_dashboard_screen.dart` |
| **Modify** | `apps/mobile/lib/app/router.dart` |
| **Modify** | `apps/mobile/test/unit/features/donor/domain/usecases/watch_active_batches_usecase_test.dart` |
| **Modify** | `apps/mobile/test/unit/features/donor/domain/usecases/get_donor_metrics_usecase_test.dart` |
| **Modify** | `apps/mobile/test/unit/features/donor/domain/usecases/create_batch_usecase_test.dart` |
| **Create** | `apps/mobile/test/unit/features/donor/domain/usecases/watch_all_batches_usecase_test.dart` |
| **Create** | `apps/mobile/test/unit/features/donor/domain/usecases/watch_batch_by_id_usecase_test.dart` |
| **Create** | `apps/mobile/test/widget/features/donor/donor_history_screen_test.dart` |
| **Create** | `apps/mobile/test/widget/features/donor/batch_detail_screen_test.dart` |

---

## Task 1: Add `volunteerName` to `Batch` Entity + Update Mapper

**Files:**
- Modify: `apps/mobile/lib/features/donor/domain/entities/batch.dart`
- Modify: `apps/mobile/lib/features/donor/data/repositories/donor_repository_impl.dart`

- [ ] **Step 1: Add `volunteerName` field to `Batch`**

Replace `apps/mobile/lib/features/donor/domain/entities/batch.dart`:

```dart
import 'package:saveameal/features/donor/domain/entities/batch_item.dart';

enum BatchStatus { open, claimed, pickedUp, delivered, closed, cancelled }

class Batch {
  const Batch({
    required this.id,
    required this.donorId,
    required this.items,
    required this.pickupAddress,
    required this.status,
    this.driverId,
    this.volunteerName,
    this.beneficiaryId,
    this.photoUrl,
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
  final String? volunteerName;
  final String? beneficiaryId;
  final String? photoUrl;
  final String? qrCode;
  final int? rating;
  final String? feedback;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get weightKg => items.fold(0, (s, i) => s + i.weightKg);
  int get portions => items.length;
  String get description => items.map((i) => i.name).join(', ');
}
```

- [ ] **Step 2: Update `_toBatch` and `_fromBatch` mappers in `donor_repository_impl.dart`**

In `apps/mobile/lib/features/donor/data/repositories/donor_repository_impl.dart`, replace the `_toBatch` method:

```dart
  domain.Batch _toBatch(bm.BatchModel m) => domain.Batch(
    id: m.id,
    donorId: m.donorId,
    items: m.items.map(_toBatchItem).toList(),
    pickupAddress: m.pickupAddress,
    status: domain.BatchStatus.values.byName(m.status.name),
    driverId: m.driverId,
    volunteerName: m.volunteerName,
    beneficiaryId: m.beneficiaryId,
    photoUrl: m.photoUrl,
    qrCode: m.qrCode,
    rating: m.rating,
    feedback: m.feedback,
    createdAt: m.createdAt,
    updatedAt: m.updatedAt,
  );
```

Also replace `_fromBatch`:

```dart
  bm.BatchModel _fromBatch(domain.Batch b) => bm.BatchModel(
    id: b.id,
    donorId: b.donorId,
    items: b.items.map(_fromBatchItem).toList(),
    pickupAddress: b.pickupAddress,
    status: bm.BatchStatus.values.byName(b.status.name),
    driverId: b.driverId,
    volunteerName: b.volunteerName,
    beneficiaryId: b.beneficiaryId,
    photoUrl: b.photoUrl,
    qrCode: b.qrCode,
    rating: b.rating,
    feedback: b.feedback,
    createdAt: b.createdAt,
    updatedAt: b.updatedAt,
  );
```

- [ ] **Step 3: Run static analysis**

```bash
cd apps/mobile && flutter analyze lib/features/donor/domain/entities/batch.dart lib/features/donor/data/repositories/donor_repository_impl.dart
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/features/donor/domain/entities/batch.dart \
        apps/mobile/lib/features/donor/data/repositories/donor_repository_impl.dart
git commit -m "feat(donor): add volunteerName to Batch entity and update mapper"
```

---

## Task 2: Update `DonorRepository` Interface + Fix Existing Test Fakes

**Files:**
- Modify: `apps/mobile/lib/features/donor/domain/repositories/donor_repository.dart`
- Modify: `apps/mobile/test/unit/features/donor/domain/usecases/watch_active_batches_usecase_test.dart`
- Modify: `apps/mobile/test/unit/features/donor/domain/usecases/get_donor_metrics_usecase_test.dart`
- Modify: `apps/mobile/test/unit/features/donor/domain/usecases/create_batch_usecase_test.dart`

- [ ] **Step 1: Add two method signatures to `DonorRepository`**

Replace `apps/mobile/lib/features/donor/domain/repositories/donor_repository.dart`:

```dart
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';

abstract class DonorRepository {
  Stream<List<Batch>> watchActiveBatches(String donorId);
  Stream<DonorMetrics> watchMetrics(String donorId);
  Future<void> createBatch(Batch batch);
  Stream<List<Beneficiary>> getBeneficiaries();
  Stream<List<Batch>> watchAllBatches(String donorId);
  Stream<Batch> watchBatchById(String batchId);
}
```

- [ ] **Step 2: Add stub implementations to `watch_active_batches_usecase_test.dart`**

In `_FakeDonorRepository`, add after `getBeneficiaries()`:

```dart
  @override
  Stream<List<Batch>> watchAllBatches(String donorId) =>
      Stream.value(batchesToEmit);

  @override
  Stream<Batch> watchBatchById(String batchId) =>
      batchesToEmit.isNotEmpty
          ? Stream.value(batchesToEmit.first)
          : Stream.error(Exception('not found'));
```

- [ ] **Step 3: Add stub implementations to `get_donor_metrics_usecase_test.dart`**

In `_FakeDonorRepository`, add after the last `@override` method:

```dart
  @override
  Stream<List<Batch>> watchAllBatches(String donorId) => const Stream.empty();

  @override
  Stream<Batch> watchBatchById(String batchId) => const Stream.empty();
```

- [ ] **Step 4: Add stub implementations to `create_batch_usecase_test.dart`**

In `_FakeDonorRepository`, add after the last `@override` method:

```dart
  @override
  Stream<List<Batch>> watchAllBatches(String donorId) => const Stream.empty();

  @override
  Stream<Batch> watchBatchById(String batchId) => const Stream.empty();
```

- [ ] **Step 5: Run existing unit tests**

```bash
cd apps/mobile && flutter test test/unit/features/donor/
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/donor/domain/repositories/donor_repository.dart \
        apps/mobile/test/unit/features/donor/domain/usecases/watch_active_batches_usecase_test.dart \
        apps/mobile/test/unit/features/donor/domain/usecases/get_donor_metrics_usecase_test.dart \
        apps/mobile/test/unit/features/donor/domain/usecases/create_batch_usecase_test.dart
git commit -m "feat(donor): add watchAllBatches + watchBatchById to DonorRepository interface"
```

---

## Task 3: Add `watchAllBatchesForDonor` to `FirestoreService` + Implement Datasource + Repository

**Files:**
- Modify: `apps/mobile/lib/services/firestore_service.dart`
- Modify: `apps/mobile/lib/features/donor/data/datasources/donor_remote_datasource.dart`
- Modify: `apps/mobile/lib/features/donor/data/repositories/donor_repository_impl.dart`

- [ ] **Step 1: Add `watchAllBatchesForDonor` to `FirestoreService`**

After the `watchActiveBatchesForDonor` method (near the end of the file), add:

```dart
  /// All batches for this donor regardless of status. Sorted client-side.
  Stream<List<BatchModel>> watchAllBatchesForDonor(String donorId) => _db
      .collection(FirestoreConstants.batches)
      .where('donorId', isEqualTo: donorId)
      .snapshots()
      .map(
        (qs) => qs.docs
            .map(
              (d) => BatchModel.fromJson(_normalise({...d.data(), 'id': d.id})),
            )
            .toList(),
      );
```

Note: `watchBatch(String batchId)` already exists — no changes needed.

- [ ] **Step 2: Replace `donor_remote_datasource.dart`**

```dart
import 'package:saveameal/core/exceptions/batch_exceptions.dart';
import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/core/models/beneficiary_model.dart';
import 'package:saveameal/core/models/impact_metrics_model.dart';
import 'package:saveameal/services/firestore_service.dart';

abstract class DonorRemoteDatasource {
  Stream<List<BatchModel>> watchActiveBatches(String donorId);
  Stream<ImpactMetricsModel> watchMetrics(String donorId);
  Future<void> createBatch(BatchModel batch);
  Stream<List<BeneficiaryModel>> getBeneficiaries();
  Stream<List<BatchModel>> watchAllBatches(String donorId);
  Stream<BatchModel> watchBatchById(String batchId);
}

class DonorRemoteDatasourceImpl implements DonorRemoteDatasource {
  const DonorRemoteDatasourceImpl(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Stream<List<BatchModel>> watchActiveBatches(String donorId) =>
      _firestoreService.watchActiveBatchesForDonor(donorId);

  @override
  Stream<ImpactMetricsModel> watchMetrics(String donorId) => _firestoreService
      .watchDonorMetrics(donorId)
      .map((m) => m ?? ImpactMetricsModel(id: donorId));

  @override
  Future<void> createBatch(BatchModel batch) =>
      _firestoreService.createBatch(batch);

  @override
  Stream<List<BeneficiaryModel>> getBeneficiaries() =>
      _firestoreService.getBeneficiaries();

  @override
  Stream<List<BatchModel>> watchAllBatches(String donorId) =>
      _firestoreService.watchAllBatchesForDonor(donorId).map((models) {
        final sorted = [...models]
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)),
          );
        return sorted;
      });

  @override
  Stream<BatchModel> watchBatchById(String batchId) =>
      _firestoreService.watchBatch(batchId).map((m) {
        if (m == null) throw BatchNotFoundException(batchId);
        return m;
      });
}
```

- [ ] **Step 3: Add `watchAllBatches` and `watchBatchById` implementations to `DonorRepositoryImpl`**

In `donor_repository_impl.dart`, add after `getBeneficiaries()`:

```dart
  @override
  Stream<List<domain.Batch>> watchAllBatches(String donorId) =>
      _datasource.watchAllBatches(donorId).map(
        (models) => models.map(_toBatch).toList(),
      );

  @override
  Stream<domain.Batch> watchBatchById(String batchId) =>
      _datasource.watchBatchById(batchId).map(_toBatch);
```

- [ ] **Step 4: Run static analysis**

```bash
cd apps/mobile && flutter analyze lib/services/firestore_service.dart lib/features/donor/data/
```

Expected: no issues.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/services/firestore_service.dart \
        apps/mobile/lib/features/donor/data/datasources/donor_remote_datasource.dart \
        apps/mobile/lib/features/donor/data/repositories/donor_repository_impl.dart
git commit -m "feat(donor): implement watchAllBatches + watchBatchById in datasource and repository"
```

---

## Task 4: Create Use Cases + Unit Tests

**Files:**
- Create: `apps/mobile/lib/features/donor/domain/usecases/watch_all_batches_usecase.dart`
- Create: `apps/mobile/lib/features/donor/domain/usecases/watch_batch_by_id_usecase.dart`
- Create: `apps/mobile/test/unit/features/donor/domain/usecases/watch_all_batches_usecase_test.dart`
- Create: `apps/mobile/test/unit/features/donor/domain/usecases/watch_batch_by_id_usecase_test.dart`

- [ ] **Step 1: Write failing test for `WatchAllBatchesUsecase`**

Create `apps/mobile/test/unit/features/donor/domain/usecases/watch_all_batches_usecase_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';
import 'package:saveameal/features/donor/domain/usecases/watch_all_batches_usecase.dart';

class _FakeDonorRepository implements DonorRepository {
  final List<Batch> batches;
  _FakeDonorRepository({required this.batches});

  @override
  Stream<List<Batch>> watchActiveBatches(String donorId) =>
      Stream.value(batches);
  @override
  Stream<DonorMetrics> watchMetrics(String donorId) =>
      Stream.value(DonorMetrics.empty);
  @override
  Future<void> createBatch(Batch batch) async {}
  @override
  Stream<List<Beneficiary>> getBeneficiaries() => const Stream.empty();
  @override
  Stream<List<Batch>> watchAllBatches(String donorId) =>
      Stream.value(batches);
  @override
  Stream<Batch> watchBatchById(String batchId) =>
      Stream.value(batches.firstWhere((b) => b.id == batchId));
}

Batch _makeBatch(String id, BatchStatus status) => Batch(
  id: id,
  donorId: 'donor-1',
  items: const [],
  pickupAddress: '1 Test St',
  status: status,
  createdAt: DateTime(2026, 5, 23),
);

void main() {
  group('WatchAllBatchesUsecase', () {
    test('delegates to repository.watchAllBatches and emits all statuses',
        () async {
      final batches = [
        _makeBatch('aaaaaaaa', BatchStatus.open),
        _makeBatch('bbbbbbbb', BatchStatus.closed),
        _makeBatch('cccccccc', BatchStatus.delivered),
      ];
      final usecase = WatchAllBatchesUsecase(_FakeDonorRepository(batches: batches));

      final result = await usecase.call('donor-1').first;

      expect(result.length, 3);
      expect(result.map((b) => b.id), containsAll(['aaaaaaaa', 'bbbbbbbb', 'cccccccc']));
    });

    test('emits empty list when repository emits empty list', () async {
      final usecase = WatchAllBatchesUsecase(_FakeDonorRepository(batches: []));

      final result = await usecase.call('donor-1').first;

      expect(result, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```bash
cd apps/mobile && flutter test test/unit/features/donor/domain/usecases/watch_all_batches_usecase_test.dart 2>&1 | head -5
```

Expected: compilation error — `WatchAllBatchesUsecase` not found.

- [ ] **Step 3: Create `WatchAllBatchesUsecase`**

Create `apps/mobile/lib/features/donor/domain/usecases/watch_all_batches_usecase.dart`:

```dart
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';

class WatchAllBatchesUsecase {
  const WatchAllBatchesUsecase(this._repository);

  final DonorRepository _repository;

  Stream<List<Batch>> call(String donorId) =>
      _repository.watchAllBatches(donorId);
}
```

- [ ] **Step 4: Write failing test for `WatchBatchByIdUsecase`**

Create `apps/mobile/test/unit/features/donor/domain/usecases/watch_batch_by_id_usecase_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';
import 'package:saveameal/features/donor/domain/usecases/watch_batch_by_id_usecase.dart';

class _FakeDonorRepository implements DonorRepository {
  final Batch? batch;
  _FakeDonorRepository({this.batch});

  @override
  Stream<List<Batch>> watchActiveBatches(String donorId) =>
      Stream.value(batch != null ? [batch!] : []);
  @override
  Stream<DonorMetrics> watchMetrics(String donorId) =>
      Stream.value(DonorMetrics.empty);
  @override
  Future<void> createBatch(Batch b) async {}
  @override
  Stream<List<Beneficiary>> getBeneficiaries() => const Stream.empty();
  @override
  Stream<List<Batch>> watchAllBatches(String donorId) =>
      Stream.value(batch != null ? [batch!] : []);
  @override
  Stream<Batch> watchBatchById(String batchId) =>
      batch != null ? Stream.value(batch!) : Stream.error(Exception('not found'));
}

void main() {
  group('WatchBatchByIdUsecase', () {
    test('delegates to repository and emits Batch', () async {
      final b = Batch(
        id: 'batch001',
        donorId: 'donor-1',
        items: const [],
        pickupAddress: '1 Test St',
        status: BatchStatus.claimed,
        volunteerName: 'Nattapong',
        createdAt: DateTime(2026, 5, 23),
      );
      final usecase = WatchBatchByIdUsecase(_FakeDonorRepository(batch: b));

      final result = await usecase.call('batch001').first;

      expect(result.id, 'batch001');
      expect(result.status, BatchStatus.claimed);
      expect(result.volunteerName, 'Nattapong');
    });

    test('emits error when repository stream errors', () async {
      final usecase = WatchBatchByIdUsecase(_FakeDonorRepository(batch: null));

      expect(usecase.call('missing'), emitsError(isA<Exception>()));
    });
  });
}
```

- [ ] **Step 5: Run to verify it fails**

```bash
cd apps/mobile && flutter test test/unit/features/donor/domain/usecases/watch_batch_by_id_usecase_test.dart 2>&1 | head -5
```

Expected: compilation error — `WatchBatchByIdUsecase` not found.

- [ ] **Step 6: Create `WatchBatchByIdUsecase`**

Create `apps/mobile/lib/features/donor/domain/usecases/watch_batch_by_id_usecase.dart`:

```dart
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_repository.dart';

class WatchBatchByIdUsecase {
  const WatchBatchByIdUsecase(this._repository);

  final DonorRepository _repository;

  Stream<Batch> call(String batchId) => _repository.watchBatchById(batchId);
}
```

- [ ] **Step 7: Run both use case tests**

```bash
cd apps/mobile && flutter test test/unit/features/donor/domain/usecases/watch_all_batches_usecase_test.dart test/unit/features/donor/domain/usecases/watch_batch_by_id_usecase_test.dart
```

Expected: 4 tests pass.

- [ ] **Step 8: Commit**

```bash
git add apps/mobile/lib/features/donor/domain/usecases/watch_all_batches_usecase.dart \
        apps/mobile/lib/features/donor/domain/usecases/watch_batch_by_id_usecase.dart \
        apps/mobile/test/unit/features/donor/domain/usecases/watch_all_batches_usecase_test.dart \
        apps/mobile/test/unit/features/donor/domain/usecases/watch_batch_by_id_usecase_test.dart
git commit -m "feat(donor): add WatchAllBatchesUsecase + WatchBatchByIdUsecase with unit tests"
```

---

## Task 5: Add Riverpod Providers + Run Codegen

**Files:**
- Modify: `apps/mobile/lib/features/donor/presentation/providers/donor_provider.dart`

- [ ] **Step 1: Add imports and 4 new providers**

Add to the import block at the top of `donor_provider.dart`:

```dart
import 'package:saveameal/features/donor/domain/usecases/watch_all_batches_usecase.dart';
import 'package:saveameal/features/donor/domain/usecases/watch_batch_by_id_usecase.dart';
```

Append to the bottom of `donor_provider.dart` (before the end of file):

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

- [ ] **Step 2: Run codegen**

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```

Expected: completes without errors. `donor_provider.g.dart` updated with `allBatchesProvider`, `batchByIdProvider`, `watchAllBatchesUsecaseProvider`, `watchBatchByIdUsecaseProvider`.

- [ ] **Step 3: Run analysis**

```bash
cd apps/mobile && flutter analyze lib/features/donor/presentation/providers/
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/features/donor/presentation/providers/donor_provider.dart
git commit -m "feat(donor): add allBatchesProvider + batchByIdProvider Riverpod providers"
```

---

## Task 6: Implement `DonorHistoryScreen` (Test-First)

**Files:**
- Create: `apps/mobile/test/widget/features/donor/donor_history_screen_test.dart`
- Create: `apps/mobile/lib/features/donor/presentation/screens/donor_history_screen.dart`

- [ ] **Step 1: Write the failing widget test**

Create `apps/mobile/test/widget/features/donor/donor_history_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/features/donor/presentation/screens/donor_history_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

const _testUser = AppUser(
  uid: 'donor-uid',
  name: 'Test Donor',
  email: 'test@donor.com',
  role: UserRole.donor,
);

Batch _makeBatch({required String id, BatchStatus status = BatchStatus.open}) =>
    Batch(
      id: id,
      donorId: 'donor-uid',
      items: const [],
      pickupAddress: '1 Test Road',
      status: status,
      createdAt: DateTime(2026, 5, 23, 14, 30),
    );

Widget _wrap(List<Batch> batches) {
  final router = GoRouter(
    initialLocation: '/donor/batches',
    routes: [
      GoRoute(
        path: '/donor',
        builder: (_, __) => const Scaffold(body: Text('Dashboard')),
        routes: [
          GoRoute(
            path: 'batches',
            builder: (_, __) => const DonorHistoryScreen(),
          ),
          GoRoute(
            path: 'batch/:batchId',
            builder: (context, state) => Scaffold(
              body: Text('Detail ${state.pathParameters['batchId']}'),
            ),
          ),
          GoRoute(
            path: 'log',
            builder: (_, __) => const Scaffold(body: Text('Log')),
          ),
          GoRoute(
            path: 'impact',
            builder: (_, __) => const Scaffold(body: Text('Impact')),
          ),
          GoRoute(
            path: 'account',
            builder: (_, __) => const Scaffold(body: Text('Account')),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
      allBatchesProvider('donor-uid').overrideWith(
        (ref) => Stream.value(batches),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
    ),
  );
}

void main() {
  group('DonorHistoryScreen', () {
    testWidgets('shows CircularProgressIndicator while loading', (tester) async {
      final router = GoRouter(
        initialLocation: '/donor/batches',
        routes: [
          GoRoute(
            path: '/donor/batches',
            builder: (_, __) => const DonorHistoryScreen(),
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
          allBatchesProvider('donor-uid').overrideWith(
            (ref) => const Stream.empty(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('All chip shows all batches', (tester) async {
      final batches = [
        _makeBatch(id: 'aaaaaaaa', status: BatchStatus.open),
        _makeBatch(id: 'bbbbbbbb', status: BatchStatus.closed),
        _makeBatch(id: 'cccccccc', status: BatchStatus.delivered),
      ];
      await tester.pumpWidget(_wrap(batches));
      await tester.pumpAndSettle();

      expect(find.textContaining('#'), findsNWidgets(3));
    });

    testWidgets('In Progress chip shows only active-status batches',
        (tester) async {
      final batches = [
        _makeBatch(id: 'aaaaaaaa', status: BatchStatus.open),
        _makeBatch(id: 'bbbbbbbb', status: BatchStatus.closed),
        _makeBatch(id: 'cccccccc', status: BatchStatus.claimed),
      ];
      await tester.pumpWidget(_wrap(batches));
      await tester.pumpAndSettle();

      await tester.tap(find.text('In Progress'));
      await tester.pumpAndSettle();

      expect(find.textContaining('#'), findsNWidgets(2));
    });

    testWidgets('Completed chip shows only delivered/closed batches',
        (tester) async {
      final batches = [
        _makeBatch(id: 'aaaaaaaa', status: BatchStatus.open),
        _makeBatch(id: 'bbbbbbbb', status: BatchStatus.closed),
        _makeBatch(id: 'cccccccc', status: BatchStatus.delivered),
      ];
      await tester.pumpWidget(_wrap(batches));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.textContaining('#'), findsNWidgets(2));
    });

    testWidgets('shows empty state when no batches', (tester) async {
      await tester.pumpWidget(_wrap([]));
      await tester.pumpAndSettle();

      expect(find.text('No donations yet'), findsOneWidget);
    });

    testWidgets('tapping a batch card navigates to /donor/batch/:id',
        (tester) async {
      await tester.pumpWidget(
        _wrap([_makeBatch(id: 'abc12345', status: BatchStatus.open)]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('#').first);
      await tester.pumpAndSettle();

      expect(find.text('Detail abc12345'), findsOneWidget);
    });

    testWidgets('search filters by batch short ID', (tester) async {
      final batches = [
        _makeBatch(id: 'aaaaaaaa', status: BatchStatus.open),
        _makeBatch(id: 'bbbbbbbb', status: BatchStatus.open),
      ];
      await tester.pumpWidget(_wrap(batches));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'aaaa');
      await tester.pumpAndSettle();

      expect(find.textContaining('#'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

```bash
cd apps/mobile && flutter test test/widget/features/donor/donor_history_screen_test.dart 2>&1 | head -5
```

Expected: compilation error — `DonorHistoryScreen` not found.

- [ ] **Step 3: Implement `DonorHistoryScreen`**

Create `apps/mobile/lib/features/donor/presentation/screens/donor_history_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/features/donor/presentation/widgets/donor_bottom_nav.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

enum _HistoryFilter { all, completed, inProgress }

class DonorHistoryScreen extends ConsumerStatefulWidget {
  const DonorHistoryScreen({super.key});

  @override
  ConsumerState<DonorHistoryScreen> createState() =>
      _DonorHistoryScreenState();
}

class _DonorHistoryScreenState extends ConsumerState<DonorHistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;
  String _searchQuery = '';
  int _currentPage = 0;
  static const _pageSize = 5;

  List<Batch> _applyFilterAndSearch(List<Batch> batches) {
    var filtered = switch (_filter) {
      _HistoryFilter.all => batches,
      _HistoryFilter.completed => batches
          .where(
            (b) =>
                b.status == BatchStatus.delivered ||
                b.status == BatchStatus.closed,
          )
          .toList(),
      _HistoryFilter.inProgress => batches
          .where(
            (b) =>
                b.status == BatchStatus.open ||
                b.status == BatchStatus.claimed ||
                b.status == BatchStatus.pickedUp,
          )
          .toList(),
    };

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((b) {
        final shortId =
            b.id.substring(0, b.id.length.clamp(0, 4)).toLowerCase();
        final dateStr =
            b.createdAt != null ? _formatDate(b.createdAt!).toLowerCase() : '';
        return shortId.contains(q) || dateStr.contains(q);
      }).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final donorId = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final batchesAsync = donorId.isEmpty
        ? const AsyncValue<List<Batch>>.loading()
        : ref.watch(allBatchesProvider(donorId));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Donation History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/donor/log'),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SearchBar(
              onChanged: (q) => setState(() {
                _searchQuery = q;
                _currentPage = 0;
              }),
            ),
            _FilterChipsRow(
              selected: _filter,
              onChanged: (f) => setState(() {
                _filter = f;
                _currentPage = 0;
              }),
            ),
            Expanded(
              child: batchesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => _ErrorState(
                  onRetry: () => ref.invalidate(allBatchesProvider(donorId)),
                ),
                data: (allBatches) {
                  final filtered = _applyFilterAndSearch(allBatches);
                  if (filtered.isEmpty) return const _EmptyState();

                  final totalPages =
                      ((filtered.length - 1) ~/ _pageSize) + 1;
                  final page = _currentPage.clamp(0, totalPages - 1);
                  final start = page * _pageSize;
                  final end =
                      (start + _pageSize).clamp(0, filtered.length);
                  final pageBatches = filtered.sublist(start, end);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Batches',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${filtered.length} Total',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.md,
                          ),
                          itemCount: pageBatches.length,
                          itemBuilder: (context, i) =>
                              _BatchHistoryCard(batch: pageBatches[i]),
                        ),
                      ),
                      if (totalPages > 1)
                        _PaginationRow(
                          currentPage: page,
                          totalPages: totalPages,
                          onPageChanged: (p) =>
                              setState(() => _currentPage = p),
                        ),
                      const SizedBox(height: Spacing.md),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DonorBottomNav(
        currentIndex: 2,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/donor');
            case 1:
              context.go('/donor/impact');
            case 2:
              context.go('/donor/batches');
            case 3:
              context.go('/donor/account');
          }
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month]} ${dt.day}';
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search batch ID or date...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: cs.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
        ),
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({required this.selected, required this.onChanged});

  final _HistoryFilter selected;
  final ValueChanged<_HistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: selected == _HistoryFilter.all,
            onTap: () => onChanged(_HistoryFilter.all),
            cs: cs,
          ),
          const SizedBox(width: Spacing.sm),
          _FilterChip(
            label: 'Completed',
            isSelected: selected == _HistoryFilter.completed,
            onTap: () => onChanged(_HistoryFilter.completed),
            cs: cs,
          ),
          const SizedBox(width: Spacing.sm),
          _FilterChip(
            label: 'In Progress',
            isSelected: selected == _HistoryFilter.inProgress,
            onTap: () => onChanged(_HistoryFilter.inProgress),
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.cs,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: isSelected,
    onSelected: (_) => onTap(),
    selectedColor: cs.primary,
    labelStyle: TextStyle(
      color: isSelected ? cs.onPrimary : cs.onSurface,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
    ),
    checkmarkColor: cs.onPrimary,
  );
}

class _BatchHistoryCard extends StatelessWidget {
  const _BatchHistoryCard({required this.batch});

  final Batch batch;

  Color _accentColor(BatchStatus s, AppColors ac, ColorScheme cs) =>
      switch (s) {
        BatchStatus.delivered || BatchStatus.closed => cs.primary,
        BatchStatus.open ||
        BatchStatus.claimed ||
        BatchStatus.pickedUp => ac.warning,
        _ => ac.danger,
      };

  IconData _categoryIcon(List items) => items.isEmpty
      ? Icons.inventory_2_outlined
      : Icons.bakery_dining;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final accent = _accentColor(batch.status, ac, cs);
    final shortId =
        batch.id.substring(0, batch.id.length.clamp(0, 4)).toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/donor/batch/${batch.id}'),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                const SizedBox(width: Spacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: accent,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: Spacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#$shortId',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (batch.createdAt != null)
                          Text(
                            _formatDateTime(batch.createdAt!),
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: Spacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.scale_outlined,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${batch.weightKg.toStringAsFixed(1)} kg',
                              style: textTheme.bodySmall,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${batch.portions} items',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.sm,
                  ),
                  child: _StatusBadge(status: batch.status),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month]} ${dt.day}, ${dt.year} · $h:$m $ampm';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BatchStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final isDone =
        status == BatchStatus.delivered || status == BatchStatus.closed;
    final color = isDone ? cs.primary : ac.warning;
    final icon = isDone ? Icons.check_circle : Icons.sync;
    final label = isDone ? 'DONE' : 'ACTIVE';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PaginationRow extends StatelessWidget {
  const _PaginationRow({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pages = List.generate(totalPages, (i) => i);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
          ),
          ...pages.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: p == currentPage
                  ? FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                        backgroundColor: cs.primary,
                      ),
                      child: Text('${p + 1}'),
                    )
                  : OutlinedButton(
                      onPressed: () => onPageChanged(p),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text('${p + 1}'),
                    ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.volunteer_activism, size: 64, color: cs.primary),
          const SizedBox(height: Spacing.md),
          Text(
            'No donations yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: Spacing.sm),
          const Text('Could not load donations'),
          const SizedBox(height: Spacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run widget tests**

```bash
cd apps/mobile && flutter test test/widget/features/donor/donor_history_screen_test.dart
```

Expected: all 7 tests pass.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/donor/presentation/screens/donor_history_screen.dart \
        apps/mobile/test/widget/features/donor/donor_history_screen_test.dart
git commit -m "feat(donor): implement DonorHistoryScreen matching Figma design"
```

---

## Task 7: Implement `BatchDetailScreen` (Test-First)

**Files:**
- Create: `apps/mobile/test/widget/features/donor/batch_detail_screen_test.dart`
- Create: `apps/mobile/lib/features/donor/presentation/screens/batch_detail_screen.dart`

- [ ] **Step 1: Write the failing widget test**

Create `apps/mobile/test/widget/features/donor/batch_detail_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/batch_item.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/features/donor/presentation/screens/batch_detail_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

Batch _makeBatch({
  String id = 'abc12345',
  BatchStatus status = BatchStatus.open,
  String? driverId,
  String? volunteerName,
  List<BatchItem> items = const [],
  String pickupAddress = '100 Central Hub Road',
}) => Batch(
  id: id,
  donorId: 'donor-uid',
  items: items,
  pickupAddress: pickupAddress,
  status: status,
  driverId: driverId,
  volunteerName: volunteerName,
  createdAt: DateTime(2026, 5, 23, 14, 30),
);

Widget _wrap(Batch batch) {
  final router = GoRouter(
    initialLocation: '/donor/batch/${batch.id}',
    routes: [
      GoRoute(
        path: '/donor',
        builder: (_, __) => const Scaffold(body: Text('Dashboard')),
        routes: [
          GoRoute(
            path: 'batch/:batchId',
            builder: (context, state) =>
                BatchDetailScreen(batchId: state.pathParameters['batchId']!),
            routes: [
              GoRoute(
                path: 'qr',
                builder: (context, state) => Scaffold(
                  body: Text('QR ${state.pathParameters['batchId']}'),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      batchByIdProvider(batch.id).overrideWith(
        (ref) => Stream.value(batch),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
    ),
  );
}

void main() {
  group('BatchDetailScreen', () {
    testWidgets('shows loading indicator while batch loading', (tester) async {
      final router = GoRouter(
        initialLocation: '/donor/batch/abc12345',
        routes: [
          GoRoute(
            path: '/donor/batch/:batchId',
            builder: (context, state) =>
                BatchDetailScreen(batchId: state.pathParameters['batchId']!),
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          batchByIdProvider('abc12345').overrideWith(
            (ref) => const Stream.empty(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows status-based heading', (tester) async {
      await tester.pumpWidget(
          _wrap(_makeBatch(status: BatchStatus.pickedUp)));
      await tester.pumpAndSettle();

      expect(find.text('Collected Successfully'), findsOneWidget);
    });

    testWidgets('shows Total Weight and Total Items summary cards',
        (tester) async {
      final items = [
        BatchItem(
          name: 'Bread',
          category: FoodCategory.bakery,
          weightKg: 2.5,
          expiryTime: DateTime(2026, 6, 10),
        ),
      ];
      await tester.pumpWidget(_wrap(_makeBatch(items: items)));
      await tester.pumpAndSettle();

      expect(find.text('Total Weight'), findsOneWidget);
      expect(find.text('Total Items'), findsOneWidget);
      expect(find.text('2.5 kg'), findsOneWidget);
      expect(find.text('1 Products'), findsOneWidget);
    });

    testWidgets('shows Inventory Breakdown section with item names',
        (tester) async {
      final items = [
        BatchItem(
          name: 'Sourdough Loaves',
          category: FoodCategory.bakery,
          weightKg: 5.0,
          expiryTime: DateTime(2026, 6, 10),
        ),
        BatchItem(
          name: 'Organic Apples',
          category: FoodCategory.produce,
          weightKg: 8.0,
          expiryTime: DateTime(2026, 6, 10),
        ),
      ];
      await tester.pumpWidget(_wrap(_makeBatch(items: items)));
      await tester.pumpAndSettle();

      expect(find.text('Inventory Breakdown'), findsOneWidget);
      expect(find.text('Sourdough Loaves'), findsOneWidget);
      expect(find.text('Organic Apples'), findsOneWidget);
    });

    testWidgets('hides driver section when volunteerName is null',
        (tester) async {
      await tester.pumpWidget(
          _wrap(_makeBatch(volunteerName: null)));
      await tester.pumpAndSettle();

      expect(find.text('Collected by'), findsNothing);
    });

    testWidgets('shows driver section with volunteer name', (tester) async {
      await tester.pumpWidget(
        _wrap(_makeBatch(
          driverId: 'driver-1',
          volunteerName: 'Nattapong',
          status: BatchStatus.pickedUp,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Collected by'), findsOneWidget);
      expect(find.textContaining('Nattapong'), findsOneWidget);
    });

    testWidgets('shows pickup address card', (tester) async {
      await tester.pumpWidget(
        _wrap(_makeBatch(pickupAddress: 'Central Distribution Hub')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Central Distribution Hub'), findsOneWidget);
    });

    testWidgets('QR button visible only on open batch', (tester) async {
      await tester.pumpWidget(_wrap(_makeBatch(status: BatchStatus.open)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.qr_code), findsOneWidget);
    });

    testWidgets('QR button not visible on non-open batch', (tester) async {
      await tester.pumpWidget(
          _wrap(_makeBatch(status: BatchStatus.delivered)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.qr_code), findsNothing);
    });

    testWidgets('QR button navigates to qr sub-route', (tester) async {
      await tester.pumpWidget(
        _wrap(_makeBatch(id: 'abc12345', status: BatchStatus.open)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.qr_code));
      await tester.pumpAndSettle();

      expect(find.text('QR abc12345'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

```bash
cd apps/mobile && flutter test test/widget/features/donor/batch_detail_screen_test.dart 2>&1 | head -5
```

Expected: compilation error — `BatchDetailScreen` not found.

- [ ] **Step 3: Implement `BatchDetailScreen`**

Create `apps/mobile/lib/features/donor/presentation/screens/batch_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/batch_item.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class BatchDetailScreen extends ConsumerWidget {
  const BatchDetailScreen({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchAsync = ref.watch(batchByIdProvider(batchId));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Batch Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          batchAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (batch) => batch.status == BatchStatus.open
                ? IconButton(
                    icon: const Icon(Icons.qr_code),
                    onPressed: () =>
                        context.push('/donor/batch/$batchId/qr'),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: batchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: Spacing.sm),
              const Text('Could not load batch'),
            ],
          ),
        ),
        data: (batch) => _BatchDetailBody(batch: batch),
      ),
    );
  }
}

class _BatchDetailBody extends StatelessWidget {
  const _BatchDetailBody({required this.batch});

  final Batch batch;

  String _statusHeading(BatchStatus s) => switch (s) {
    BatchStatus.open => 'Waiting for Pickup',
    BatchStatus.claimed => 'Driver Assigned',
    BatchStatus.pickedUp => 'Collected Successfully',
    BatchStatus.delivered => 'Delivered Successfully',
    BatchStatus.closed => 'Completed',
    BatchStatus.cancelled => 'Cancelled',
  };

  String _statusLabel(BatchStatus s) => switch (s) {
    BatchStatus.open => 'Pending',
    BatchStatus.claimed => 'Claimed',
    BatchStatus.pickedUp => 'Collected',
    BatchStatus.delivered => 'Delivered',
    BatchStatus.closed => 'Closed',
    BatchStatus.cancelled => 'Cancelled',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shortId =
        batch.id.substring(0, batch.id.length.clamp(0, 4)).toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Batch chip
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text('Batch #$shortId'),
              backgroundColor: cs.tertiaryContainer,
              labelStyle: TextStyle(color: cs.onTertiaryContainer),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          // Status heading
          Text(
            _statusHeading(batch.status),
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (batch.createdAt != null) ...[
            const SizedBox(height: Spacing.xs),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(batch.createdAt!),
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Spacing.sm),
          // Status pill
          _StatusPill(label: 'Status: ${_statusLabel(batch.status)}'),
          const SizedBox(height: Spacing.md),
          // Summary cards row
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.scale_outlined,
                  label: 'Total Weight',
                  value: '${batch.weightKg.toStringAsFixed(1)} kg',
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Total Items',
                  value: '${batch.portions} Products',
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          // Inventory breakdown
          Text(
            'Inventory Breakdown',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Spacing.sm),
          if (batch.items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Text(
                  'No item data available',
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...batch.items.map((item) => _InventoryItemCard(item: item)),
          // Driver section
          if (batch.volunteerName != null) ...[
            const SizedBox(height: Spacing.md),
            _DriverCard(volunteerName: batch.volunteerName!),
          ],
          // Address card
          const SizedBox(height: Spacing.md),
          _AddressCard(address: batch.pickupAddress),
          const SizedBox(height: Spacing.md),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month]} ${dt.day}, $h:$m $ampm';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: cs.onPrimary, size: 18),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Icon(icon, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({required this.item});

  final BatchItem item;

  static const _icons = {
    FoodCategory.bakery: Icons.bakery_dining,
    FoodCategory.produce: Icons.eco,
    FoodCategory.dairy: Icons.egg_outlined,
    FoodCategory.meat: Icons.set_meal,
    FoodCategory.beverages: Icons.local_cafe_outlined,
    FoodCategory.other: Icons.category_outlined,
  };

  static const _categoryNames = {
    FoodCategory.bakery: 'Bakery',
    FoodCategory.produce: 'Produce',
    FoodCategory.dairy: 'Dairy',
    FoodCategory.meat: 'Meat',
    FoodCategory.beverages: 'Beverages',
    FoodCategory.other: 'Other',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, color: cs.primary),
            Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.primaryContainer,
                    child: Icon(
                      _icons[item.category] ?? Icons.category_outlined,
                      color: cs.onPrimaryContainer,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _categoryNames[item.category] ?? 'Other',
                          style: textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${item.weightKg.toStringAsFixed(1)}kg',
                      style: textTheme.bodySmall,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.volunteerName});

  final String volunteerName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final initials = volunteerName.isNotEmpty
        ? volunteerName[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        border: Border.all(
          color: cs.outlineVariant,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.tertiaryContainer,
            child: Text(
              initials,
              style: TextStyle(color: cs.onTertiaryContainer),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collected by',
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                '$volunteerName (Driver)',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              address,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run widget tests**

```bash
cd apps/mobile && flutter test test/widget/features/donor/batch_detail_screen_test.dart
```

Expected: all 9 tests pass.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/donor/presentation/screens/batch_detail_screen.dart \
        apps/mobile/test/widget/features/donor/batch_detail_screen_test.dart
git commit -m "feat(donor): implement BatchDetailScreen matching Figma design"
```

---

## Task 8: Update Router + Dashboard `_BatchCard`

**Files:**
- Modify: `apps/mobile/lib/app/router.dart`
- Modify: `apps/mobile/lib/features/donor/presentation/screens/donor_dashboard_screen.dart`
- Modify: `apps/mobile/test/widget/features/donor/donor_dashboard_screen_test.dart`

- [ ] **Step 1: Add imports to `router.dart`**

Add after the existing donor screen imports:

```dart
import 'package:saveameal/features/donor/presentation/screens/batch_detail_screen.dart';
import 'package:saveameal/features/donor/presentation/screens/donor_history_screen.dart';
```

- [ ] **Step 2: Replace the flat `batch/:batchId/qr` route in `router.dart`**

Find:

```dart
          GoRoute(
            path: 'batch/:batchId/qr',
            builder: (context, state) =>
                BatchQrScreen(batchId: state.pathParameters['batchId']!),
          ),
```

Replace with:

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

- [ ] **Step 3: Replace the batches stub in `router.dart`**

Find:

```dart
          GoRoute(
            path: 'batches',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('All Batches'))),
          ),
```

Replace with:

```dart
          GoRoute(
            path: 'batches',
            builder: (context, state) => const DonorHistoryScreen(),
          ),
```

- [ ] **Step 4: Update `_BatchCard` in `donor_dashboard_screen.dart`**

Read the `_BatchCard` class in `donor_dashboard_screen.dart`. Find the `Card` widget inside `build`. Wrap it in an `InkWell` (or add `onTap` via `Card`'s `child` property) and remove the QR `IconButton` from trailing. The card should always show `Icon(Icons.check_circle_outline, color: ac.success)` as trailing, and the entire card taps to `/donor/batch/${batch.id}`.

The key change is wrapping the existing `Card` in `InkWell`:

```dart
  // Inside _BatchCard.build — find the Card widget and wrap it:
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: Spacing.md,
      vertical: Spacing.xs,
    ),
    child: Card(
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/donor/batch/${batch.id}'),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2_outlined, color: cs.onSurfaceVariant),
          ),
          title: Text(
            'Batch #${batch.id.substring(0, 8).toUpperCase()}',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${batch.portions} items • ${batch.weightKg.toStringAsFixed(1)}kg'
            ' • ${_statusLabel(batch.status)}'
            '${batch.createdAt != null ? ' • ${_formatDate(batch.createdAt!)}' : ''}',
            style: textTheme.bodySmall,
          ),
          trailing: Icon(Icons.check_circle_outline, color: ac.success),
        ),
      ),
    ),
  );
```

Keep the existing `_statusLabel` and `_formatDate` helpers unchanged.

- [ ] **Step 5: Update `donor_dashboard_screen_test.dart` router**

In `_buildRouter()`, replace the flat `batch/:batchId/qr` route with the nested structure:

```dart
        GoRoute(
          path: 'batch/:batchId',
          builder: (context, state) =>
              Scaffold(body: Text('Detail ${state.pathParameters['batchId']}')),
          routes: [
            GoRoute(
              path: 'qr',
              builder: (context, state) =>
                  Scaffold(body: Text('QR ${state.pathParameters['batchId']}')),
            ),
          ],
        ),
```

- [ ] **Step 6: Run the full test suite**

```bash
cd apps/mobile && flutter test
```

Expected: all tests pass.

- [ ] **Step 7: Run analysis + format**

```bash
cd apps/mobile && flutter analyze && dart format --set-exit-if-changed .
```

Expected: no issues.

- [ ] **Step 8: Commit**

```bash
git add apps/mobile/lib/app/router.dart \
        apps/mobile/lib/features/donor/presentation/screens/donor_dashboard_screen.dart \
        apps/mobile/test/widget/features/donor/donor_dashboard_screen_test.dart
git commit -m "feat(donor): wire batch detail + history routes; make dashboard cards tappable"
```

---

## Task 9: Final Verification

- [ ] **Step 1: Run full test suite**

```bash
cd apps/mobile && flutter test --reporter=compact
```

Expected: all tests pass, 0 failures.

- [ ] **Step 2: Static analysis**

```bash
cd apps/mobile && flutter analyze
```

Expected: No issues found.

- [ ] **Step 3: Format check**

```bash
cd apps/mobile && dart format --set-exit-if-changed .
```

Expected: 0 files changed.

- [ ] **Step 4: Codegen check**

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```

Expected: completes without errors.

- [ ] **Step 5: Write session log outcome**

Append to `docs/agent-log-kimtaeman.md`:

```
Outcome: Implemented DonorHistoryScreen (searchable, paginated 5/page, All/Completed/In Progress filter chips, FAB) and BatchDetailScreen (status heading, summary cards, inventory breakdown, driver card, address card). Added volunteerName to Batch entity. Added watchAllBatches + watchBatchById across all layers (FirestoreService → datasource → repository → use cases → providers). Router restructured with batch/:batchId as parent of qr sub-route. Dashboard _BatchCard made tappable. Matches Figma reference designs: "Donation History (5 per page).png" and "Batch Details.png".
Decisions: BatchModel already had volunteerName — only Batch entity needed updating. Pagination is client-side (load all, slice by page). Timeline removed — Figma shows summary cards instead. Driver avatar uses initials CircleAvatar (no driver photo in data model). Address card uses styled container (no real map — pickup address is string, not coordinates).
Handoff: QA-engineer to validate filter chips, pagination, and navigation on device. Cloud Functions must write volunteerName on batch claim (already done in FirestoreService.acceptJob). No schema changes required.
Review: PENDING
```
