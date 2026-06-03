# Donor Batch Detail + Donation History Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement `DonorHistoryScreen` (`/donor/batches`) showing all batches with status filter chips, and `BatchDetailScreen` (`/donor/batch/:batchId`) showing item list, status timeline, and driver info with the QR button.

**Architecture:** Extend `DonorRepository` with `watchAllBatches` and `watchBatchById`; `BatchModel` already has the three lifecycle timestamps so only `Batch` entity needs updating; both screens are `ConsumerStatefulWidget`s reading from new Riverpod family providers.

**Tech Stack:** Flutter, Riverpod (riverpod_annotation codegen), GoRouter, Firestore (`cloud_firestore`), `freezed`, `go_router`

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| **Modify** | `lib/features/donor/domain/entities/batch.dart` | Add `claimedAt`, `pickedUpAt`, `deliveredAt` fields |
| **Modify** | `lib/features/donor/data/repositories/donor_repository_impl.dart` | Map new timestamp fields in `_toBatch` / `_fromBatch` |
| **Modify** | `lib/services/firestore_service.dart` | Add `watchAllBatchesForDonor` (no status filter) |
| **Modify** | `lib/features/donor/data/datasources/donor_remote_datasource.dart` | Add `watchAllBatches` + `watchBatchById` abstract + impls |
| **Modify** | `lib/features/donor/domain/repositories/donor_repository.dart` | Add `watchAllBatches` + `watchBatchById` signatures |
| **Modify** | `lib/features/donor/data/repositories/donor_repository_impl.dart` | Implement both new methods |
| **Create** | `lib/features/donor/domain/usecases/watch_all_batches_usecase.dart` | Single-method use case |
| **Create** | `lib/features/donor/domain/usecases/watch_batch_by_id_usecase.dart` | Single-method use case |
| **Modify** | `lib/features/donor/presentation/providers/donor_provider.dart` | Add 4 new `@riverpod` providers |
| **Create** | `lib/features/donor/presentation/screens/donor_history_screen.dart` | History screen + filter chips |
| **Create** | `lib/features/donor/presentation/screens/batch_detail_screen.dart` | Detail screen (items, timeline, driver) |
| **Modify** | `lib/features/donor/presentation/screens/donor_dashboard_screen.dart` | Make `_BatchCard` tappable; remove QR button from card |
| **Modify** | `lib/app/router.dart` | Nest QR under `batch/:batchId`; replace batches stub; add imports |
| **Modify** | `test/unit/features/donor/domain/usecases/watch_active_batches_usecase_test.dart` | Add stub impls for new interface methods |
| **Modify** | `test/unit/features/donor/domain/usecases/get_donor_metrics_usecase_test.dart` | Add stub impls for new interface methods |
| **Modify** | `test/unit/features/donor/domain/usecases/create_batch_usecase_test.dart` | Add stub impls for new interface methods |
| **Create** | `test/unit/features/donor/domain/usecases/watch_all_batches_usecase_test.dart` | Use case unit tests |
| **Create** | `test/unit/features/donor/domain/usecases/watch_batch_by_id_usecase_test.dart` | Use case unit tests |
| **Create** | `test/widget/features/donor/donor_history_screen_test.dart` | Widget tests |
| **Create** | `test/widget/features/donor/batch_detail_screen_test.dart` | Widget tests |

---

## Task 1: Extend `Batch` Entity With Timeline Timestamps

**Files:**
- Modify: `apps/mobile/lib/features/donor/domain/entities/batch.dart`

- [ ] **Step 1: Add the three new fields to `Batch`**

Replace the entire file content:

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
    this.beneficiaryId,
    this.photoUrl,
    this.qrCode,
    this.rating,
    this.feedback,
    this.createdAt,
    this.updatedAt,
    this.claimedAt,
    this.pickedUpAt,
    this.deliveredAt,
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
  final DateTime? claimedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  double get weightKg => items.fold(0, (s, i) => s + i.weightKg);
  int get portions => items.length;
  String get description => items.map((i) => i.name).join(', ');
}
```

- [ ] **Step 2: Run static analysis to confirm no errors**

```bash
cd apps/mobile && flutter analyze lib/features/donor/domain/entities/batch.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/lib/features/donor/domain/entities/batch.dart
git commit -m "feat(donor): add claimedAt/pickedUpAt/deliveredAt to Batch entity"
```

---

## Task 2: Update `DonorRepository` Interface + Fix Existing Test Fakes

Adding two methods to the abstract class will break the three existing `_FakeDonorRepository` impls in unit tests. Fix them all in this task.

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

In the `_FakeDonorRepository` class, add these two methods after `getBeneficiaries()`:

```dart
  @override
  Stream<List<Batch>> watchAllBatches(String donorId) =>
      Stream.value(batchesToEmit);

  @override
  Stream<Batch> watchBatchById(String batchId) =>
      Stream.value(batchesToEmit.isNotEmpty
          ? batchesToEmit.first
          : throw Exception('not found'));
```

- [ ] **Step 3: Add stub implementations to `get_donor_metrics_usecase_test.dart`**

Read the file first, then add after the last `@override` method in `_FakeDonorRepository`:

```dart
  @override
  Stream<List<Batch>> watchAllBatches(String donorId) => const Stream.empty();

  @override
  Stream<Batch> watchBatchById(String batchId) => const Stream.empty();
```

- [ ] **Step 4: Add stub implementations to `create_batch_usecase_test.dart`**

Read the file first, then add after the last `@override` method in `_FakeDonorRepository`:

```dart
  @override
  Stream<List<Batch>> watchAllBatches(String donorId) => const Stream.empty();

  @override
  Stream<Batch> watchBatchById(String batchId) => const Stream.empty();
```

- [ ] **Step 5: Run existing tests to confirm they still pass**

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

## Task 3: Add `watchAllBatchesForDonor` to `FirestoreService` + Update Mapper

**Files:**
- Modify: `apps/mobile/lib/services/firestore_service.dart`
- Modify: `apps/mobile/lib/features/donor/data/repositories/donor_repository_impl.dart`

- [ ] **Step 1: Add `watchAllBatchesForDonor` to `FirestoreService`**

After the `watchActiveBatchesForDonor` method (around line 354), add:

```dart
  /// All batches for this donor regardless of status, sorted client-side by
  /// createdAt descending. No composite Firestore index needed.
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

Note: `watchBatch(String batchId)` already exists in `FirestoreService` (around line 71) — no changes needed there.

- [ ] **Step 2: Update `_toBatch` mapper in `DonorRepositoryImpl` to pass through the three new timestamps**

In `apps/mobile/lib/features/donor/data/repositories/donor_repository_impl.dart`, replace the `_toBatch` method:

```dart
  domain.Batch _toBatch(bm.BatchModel m) => domain.Batch(
    id: m.id,
    donorId: m.donorId,
    items: m.items.map(_toBatchItem).toList(),
    pickupAddress: m.pickupAddress,
    status: domain.BatchStatus.values.byName(m.status.name),
    driverId: m.driverId,
    beneficiaryId: m.beneficiaryId,
    photoUrl: m.photoUrl,
    qrCode: m.qrCode,
    rating: m.rating,
    feedback: m.feedback,
    createdAt: m.createdAt,
    updatedAt: m.updatedAt,
    claimedAt: m.claimedAt,
    pickedUpAt: m.pickedUpAt,
    deliveredAt: m.deliveredAt,
  );
```

- [ ] **Step 3: Run static analysis**

```bash
cd apps/mobile && flutter analyze lib/services/firestore_service.dart lib/features/donor/data/repositories/donor_repository_impl.dart
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/services/firestore_service.dart \
        apps/mobile/lib/features/donor/data/repositories/donor_repository_impl.dart
git commit -m "feat(donor): add watchAllBatchesForDonor to FirestoreService; map timeline timestamps in _toBatch"
```

---

## Task 4: Implement `DonorRemoteDatasource` + `DonorRepositoryImpl` New Methods

**Files:**
- Modify: `apps/mobile/lib/features/donor/data/datasources/donor_remote_datasource.dart`
- Modify: `apps/mobile/lib/features/donor/data/repositories/donor_repository_impl.dart`

- [ ] **Step 1: Add two methods to `DonorRemoteDatasource`**

Replace `apps/mobile/lib/features/donor/data/datasources/donor_remote_datasource.dart`:

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
  Stream<List<BatchModel>> watchAllBatches(String donorId) {
    return _firestoreService.watchAllBatchesForDonor(donorId).map((models) {
      final sorted = [...models]
        ..sort(
          (a, b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0)),
        );
      return sorted;
    });
  }

  @override
  Stream<BatchModel> watchBatchById(String batchId) =>
      _firestoreService.watchBatch(batchId).map((m) {
        if (m == null) throw BatchNotFoundException(batchId);
        return m;
      });
}
```

- [ ] **Step 2: Add implementations to `DonorRepositoryImpl`**

In `apps/mobile/lib/features/donor/data/repositories/donor_repository_impl.dart`, add these two method implementations after `getBeneficiaries()`:

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

- [ ] **Step 3: Run static analysis**

```bash
cd apps/mobile && flutter analyze lib/features/donor/data/
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/features/donor/data/datasources/donor_remote_datasource.dart \
        apps/mobile/lib/features/donor/data/repositories/donor_repository_impl.dart
git commit -m "feat(donor): implement watchAllBatches + watchBatchById in datasource and repository"
```

---

## Task 5: Create Use Cases

**Files:**
- Create: `apps/mobile/lib/features/donor/domain/usecases/watch_all_batches_usecase.dart`
- Create: `apps/mobile/lib/features/donor/domain/usecases/watch_batch_by_id_usecase.dart`

- [ ] **Step 1: Write the failing unit test for `WatchAllBatchesUsecase`**

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
        _makeBatch('a', BatchStatus.open),
        _makeBatch('b', BatchStatus.closed),
        _makeBatch('c', BatchStatus.delivered),
      ];
      final repo = _FakeDonorRepository(batches: batches);
      final usecase = WatchAllBatchesUsecase(repo);

      final result = await usecase.call('donor-1').first;

      expect(result.length, 3);
      expect(result.map((b) => b.id), containsAll(['a', 'b', 'c']));
    });

    test('emits empty list when repository emits empty list', () async {
      final repo = _FakeDonorRepository(batches: []);
      final usecase = WatchAllBatchesUsecase(repo);

      final result = await usecase.call('donor-1').first;

      expect(result, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails (file not found)**

```bash
cd apps/mobile && flutter test test/unit/features/donor/domain/usecases/watch_all_batches_usecase_test.dart
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

- [ ] **Step 4: Write the failing unit test for `WatchBatchByIdUsecase`**

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
  Stream<Batch> watchBatchById(String batchId) {
    if (batch == null) return Stream.error(Exception('not found'));
    return Stream.value(batch!);
  }
}

void main() {
  group('WatchBatchByIdUsecase', () {
    test('delegates to repository.watchBatchById and emits Batch', () async {
      final b = Batch(
        id: 'batch-xyz',
        donorId: 'donor-1',
        items: const [],
        pickupAddress: '1 Test St',
        status: BatchStatus.claimed,
        createdAt: DateTime(2026, 5, 23),
        claimedAt: DateTime(2026, 5, 23, 10),
      );
      final repo = _FakeDonorRepository(batch: b);
      final usecase = WatchBatchByIdUsecase(repo);

      final result = await usecase.call('batch-xyz').first;

      expect(result.id, 'batch-xyz');
      expect(result.status, BatchStatus.claimed);
      expect(result.claimedAt, DateTime(2026, 5, 23, 10));
    });

    test('emits error when repository stream errors', () async {
      final repo = _FakeDonorRepository(batch: null);
      final usecase = WatchBatchByIdUsecase(repo);

      expect(
        usecase.call('missing-id'),
        emitsError(isA<Exception>()),
      );
    });
  });
}
```

- [ ] **Step 5: Run to verify it fails**

```bash
cd apps/mobile && flutter test test/unit/features/donor/domain/usecases/watch_batch_by_id_usecase_test.dart
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

Expected: all 4 tests pass.

- [ ] **Step 8: Commit**

```bash
git add apps/mobile/lib/features/donor/domain/usecases/watch_all_batches_usecase.dart \
        apps/mobile/lib/features/donor/domain/usecases/watch_batch_by_id_usecase.dart \
        apps/mobile/test/unit/features/donor/domain/usecases/watch_all_batches_usecase_test.dart \
        apps/mobile/test/unit/features/donor/domain/usecases/watch_batch_by_id_usecase_test.dart
git commit -m "feat(donor): add WatchAllBatchesUsecase + WatchBatchByIdUsecase with unit tests"
```

---

## Task 6: Add Riverpod Providers + Run Codegen

**Files:**
- Modify: `apps/mobile/lib/features/donor/presentation/providers/donor_provider.dart`

- [ ] **Step 1: Add 4 new providers to `donor_provider.dart`**

Add these imports at the top (after existing imports):

```dart
import 'package:saveameal/features/donor/domain/usecases/watch_all_batches_usecase.dart';
import 'package:saveameal/features/donor/domain/usecases/watch_batch_by_id_usecase.dart';
```

Append these four providers at the end of the file (before the end of the `part` section — just add to the bottom):

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

- [ ] **Step 2: Run code generation**

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```

Expected: completes without errors. `donor_provider.g.dart` is regenerated with `allBatchesProvider`, `batchByIdProvider`, `watchAllBatchesUsecaseProvider`, and `watchBatchByIdUsecaseProvider`.

- [ ] **Step 3: Run static analysis**

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

## Task 7: Implement `DonorHistoryScreen` (Test-First)

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

Batch _makeBatch({
  required String id,
  BatchStatus status = BatchStatus.open,
}) => Batch(
  id: id,
  donorId: 'donor-uid',
  items: const [],
  pickupAddress: '1 Test Road',
  status: status,
  createdAt: DateTime(2026, 5, 23, 14, 30),
);

GoRouter _buildRouter(Widget screen) => GoRouter(
  initialLocation: '/donor/batches',
  routes: [
    GoRoute(
      path: '/donor',
      builder: (_, __) => const Scaffold(body: Text('Dashboard')),
      routes: [
        GoRoute(
          path: 'batches',
          builder: (_, __) => screen,
        ),
        GoRoute(
          path: 'batch/:batchId',
          builder: (context, state) =>
              Scaffold(body: Text('Detail ${state.pathParameters['batchId']}')),
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

Widget _wrap(List<Batch> batches) {
  final router = _buildRouter(const DonorHistoryScreen());
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(
        (ref) => Stream.value(_testUser),
      ),
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
    testWidgets('shows loading indicator while batches loading', (tester) async {
      final router = _buildRouter(const DonorHistoryScreen());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_testUser),
            ),
            allBatchesProvider('donor-uid').overrideWith(
              (ref) => const Stream.empty(),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('All chip shows all batches regardless of status',
        (tester) async {
      final batches = [
        _makeBatch(id: 'open11111', status: BatchStatus.open),
        _makeBatch(id: 'closed111', status: BatchStatus.closed),
        _makeBatch(id: 'delivrd1', status: BatchStatus.delivered),
      ];
      await tester.pumpWidget(_wrap(batches));
      await tester.pumpAndSettle();

      // All 3 cards rendered — each shows "Batch #XXXXXXXX"
      expect(find.textContaining('Batch #'), findsNWidgets(3));
    });

    testWidgets('Active chip filters to open/claimed/pickedUp only',
        (tester) async {
      final batches = [
        _makeBatch(id: 'open11111', status: BatchStatus.open),
        _makeBatch(id: 'closed111', status: BatchStatus.closed),
        _makeBatch(id: 'claimed11', status: BatchStatus.claimed),
      ];
      await tester.pumpWidget(_wrap(batches));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();

      // Only open + claimed remain (2 of 3)
      expect(find.textContaining('Batch #'), findsNWidgets(2));
    });

    testWidgets('Completed chip filters to delivered/closed only',
        (tester) async {
      final batches = [
        _makeBatch(id: 'open11111', status: BatchStatus.open),
        _makeBatch(id: 'closed111', status: BatchStatus.closed),
        _makeBatch(id: 'delivrd1', status: BatchStatus.delivered),
      ];
      await tester.pumpWidget(_wrap(batches));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Only delivered + closed remain (2 of 3)
      expect(find.textContaining('Batch #'), findsNWidgets(2));
    });

    testWidgets('shows empty state when no batches', (tester) async {
      await tester.pumpWidget(_wrap([]));
      await tester.pumpAndSettle();

      expect(find.text('No donations yet'), findsOneWidget);
    });

    testWidgets('tapping a batch card pushes /donor/batch/:id', (tester) async {
      final batches = [_makeBatch(id: 'abc12345', status: BatchStatus.open)];
      await tester.pumpWidget(_wrap(batches));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Batch #').first);
      await tester.pumpAndSettle();

      expect(find.text('Detail abc12345'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```bash
cd apps/mobile && flutter test test/widget/features/donor/donor_history_screen_test.dart 2>&1 | head -20
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
import 'package:saveameal/shared/theme/spacing.dart';

enum _Filter { all, active, completed }

class DonorHistoryScreen extends ConsumerStatefulWidget {
  const DonorHistoryScreen({super.key});

  @override
  ConsumerState<DonorHistoryScreen> createState() => _DonorHistoryScreenState();
}

class _DonorHistoryScreenState extends ConsumerState<DonorHistoryScreen> {
  _Filter _filter = _Filter.all;

  List<Batch> _applyFilter(List<Batch> batches) => switch (_filter) {
    _Filter.all => batches,
    _Filter.active => batches
        .where((b) =>
            b.status == BatchStatus.open ||
            b.status == BatchStatus.claimed ||
            b.status == BatchStatus.pickedUp)
        .toList(),
    _Filter.completed => batches
        .where((b) =>
            b.status == BatchStatus.delivered ||
            b.status == BatchStatus.closed)
        .toList(),
  };

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final donorId = authAsync.asData?.value?.uid ?? '';
    final batchesAsync = donorId.isEmpty
        ? const AsyncValue<List<Batch>>.loading()
        : ref.watch(allBatchesProvider(donorId));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Donation History'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusFilterChips(
              selected: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: batchesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(
                  onRetry: () => ref.invalidate(allBatchesProvider(donorId)),
                ),
                data: (batches) {
                  final filtered = _applyFilter(batches);
                  if (filtered.isEmpty) return const _EmptyState();
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.sm,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _HistoryBatchCard(batch: filtered[i]),
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
}

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({
    required this.selected,
    required this.onChanged,
  });

  final _Filter selected;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            isSelected: selected == _Filter.all,
            onTap: () => onChanged(_Filter.all),
            cs: cs,
          ),
          const SizedBox(width: Spacing.sm),
          _Chip(
            label: 'Active',
            isSelected: selected == _Filter.active,
            onTap: () => onChanged(_Filter.active),
            cs: cs,
          ),
          const SizedBox(width: Spacing.sm),
          _Chip(
            label: 'Completed',
            isSelected: selected == _Filter.completed,
            onTap: () => onChanged(_Filter.completed),
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.onPrimaryContainer,
    );
  }
}

class _HistoryBatchCard extends StatelessWidget {
  const _HistoryBatchCard({required this.batch});

  final Batch batch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shortId = batch.id.substring(0, 8).toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Card(
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/donor/batch/${batch.id}'),
          child: Column(
            children: [
              Container(height: 4, color: cs.primary),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                title: Text(
                  'Batch #$shortId',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${batch.portions} items • ${batch.weightKg.toStringAsFixed(1)}kg'
                  ' • ${_statusLabel(batch.status)}'
                  '${batch.createdAt != null ? ' • ${_formatDate(batch.createdAt!)}' : ''}',
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(BatchStatus s) => switch (s) {
    BatchStatus.open => 'Pending',
    BatchStatus.claimed => 'Claimed',
    BatchStatus.pickedUp => 'Collected',
    BatchStatus.delivered => 'Delivered',
    BatchStatus.closed => 'Closed',
    BatchStatus.cancelled => 'Cancelled',
  };

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${_monthName(dt.month)} ${dt.day}';
  }

  String _monthName(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m];
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volunteer_activism, size: 64, color: cs.primary),
            const SizedBox(height: Spacing.md),
            Text('No donations yet', style: textTheme.titleMedium),
          ],
        ),
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

- [ ] **Step 4: Run the widget tests**

```bash
cd apps/mobile && flutter test test/widget/features/donor/donor_history_screen_test.dart
```

Expected: all 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/donor/presentation/screens/donor_history_screen.dart \
        apps/mobile/test/widget/features/donor/donor_history_screen_test.dart
git commit -m "feat(donor): implement DonorHistoryScreen with status filter chips"
```

---

## Task 8: Implement `BatchDetailScreen` (Test-First)

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
  DateTime? claimedAt,
  DateTime? pickedUpAt,
  DateTime? deliveredAt,
  List<BatchItem> items = const [],
}) => Batch(
  id: id,
  donorId: 'donor-uid',
  items: items,
  pickupAddress: '1 Test Road',
  status: status,
  driverId: driverId,
  createdAt: DateTime(2026, 5, 23, 10),
  claimedAt: claimedAt,
  pickedUpAt: pickedUpAt,
  deliveredAt: deliveredAt,
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
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            batchByIdProvider('abc12345').overrideWith(
              (ref) => const Stream.empty(),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows status banner with current status label', (tester) async {
      await tester.pumpWidget(_wrap(_makeBatch(status: BatchStatus.claimed)));
      await tester.pumpAndSettle();

      expect(find.text('Claimed'), findsOneWidget);
    });

    testWidgets('shows items section with item count', (tester) async {
      final items = [
        BatchItem(
          name: 'White Bread',
          category: FoodCategory.bakery,
          weightKg: 0.5,
          expiryTime: DateTime(2026, 6, 5),
        ),
        BatchItem(
          name: 'Milk',
          category: FoodCategory.dairy,
          weightKg: 1.0,
          expiryTime: DateTime(2026, 6, 5),
        ),
      ];
      await tester.pumpWidget(_wrap(_makeBatch(items: items)));
      await tester.pumpAndSettle();

      expect(find.text('Items (2)'), findsOneWidget);
      expect(find.text('White Bread'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
    });

    testWidgets('shows — for missing timeline timestamps', (tester) async {
      await tester.pumpWidget(
        _wrap(_makeBatch(status: BatchStatus.open)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Timeline'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('shows formatted timestamps when present', (tester) async {
      await tester.pumpWidget(_wrap(_makeBatch(
        status: BatchStatus.claimed,
        claimedAt: DateTime(2026, 5, 23, 14, 30),
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('14:30'), findsOneWidget);
    });

    testWidgets('hides driver section when driverId is null', (tester) async {
      await tester.pumpWidget(_wrap(_makeBatch(driverId: null)));
      await tester.pumpAndSettle();

      expect(find.text('Driver'), findsNothing);
    });

    testWidgets('shows driver section when driverId is set', (tester) async {
      await tester.pumpWidget(_wrap(_makeBatch(driverId: 'driver-xyz')));
      await tester.pumpAndSettle();

      expect(find.text('Driver'), findsOneWidget);
      expect(find.textContaining('driver-xyz'), findsOneWidget);
    });

    testWidgets('QR button visible only on open batch', (tester) async {
      await tester.pumpWidget(_wrap(_makeBatch(status: BatchStatus.open)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.qr_code), findsOneWidget);
    });

    testWidgets('QR button not visible on non-open batch', (tester) async {
      await tester.pumpWidget(_wrap(_makeBatch(status: BatchStatus.delivered)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.qr_code), findsNothing);
    });

    testWidgets('QR button navigates to /donor/batch/:id/qr', (tester) async {
      await tester.pumpWidget(_wrap(_makeBatch(
        id: 'abc12345',
        status: BatchStatus.open,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.qr_code));
      await tester.pumpAndSettle();

      expect(find.text('QR abc12345'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```bash
cd apps/mobile && flutter test test/widget/features/donor/batch_detail_screen_test.dart 2>&1 | head -20
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
    final shortId = batchId.length >= 8
        ? batchId.substring(0, 8).toUpperCase()
        : batchId.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text('Batch #$shortId'),
        centerTitle: false,
        actions: [
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
        data: (batch) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusBanner(status: batch.status),
              const SizedBox(height: Spacing.md),
              _ItemsSection(items: batch.items),
              const SizedBox(height: Spacing.md),
              _TimelineSection(batch: batch),
              if (batch.driverId != null) ...[
                const SizedBox(height: Spacing.md),
                _DriverSection(driverId: batch.driverId!),
              ],
              const SizedBox(height: Spacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final BatchStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final (bg, fg) = switch (status) {
      BatchStatus.open => (cs.primaryContainer, cs.onPrimaryContainer),
      BatchStatus.claimed ||
      BatchStatus.pickedUp => (
          ac.warning.withValues(alpha: 0.2),
          ac.warning,
        ),
      BatchStatus.delivered ||
      BatchStatus.closed => (
          ac.success.withValues(alpha: 0.2),
          ac.success,
        ),
      BatchStatus.cancelled => (
          ac.danger.withValues(alpha: 0.2),
          ac.danger,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _statusLabel(status),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ),
    );
  }

  String _statusLabel(BatchStatus s) => switch (s) {
    BatchStatus.open => 'Pending',
    BatchStatus.claimed => 'Claimed',
    BatchStatus.pickedUp => 'Collected',
    BatchStatus.delivered => 'Delivered',
    BatchStatus.closed => 'Closed',
    BatchStatus.cancelled => 'Cancelled',
  };
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.items});

  final List<BatchItem> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items (${items.length})',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Spacing.sm),
            if (items.isEmpty)
              Text(
                'No item data available',
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, i) => _ItemRow(item: items[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final BatchItem item;

  static const _icons = {
    FoodCategory.bakery: Icons.bakery_dining,
    FoodCategory.produce: Icons.eco,
    FoodCategory.dairy: Icons.egg_outlined,
    FoodCategory.meat: Icons.set_meal,
    FoodCategory.beverages: Icons.local_cafe_outlined,
    FoodCategory.other: Icons.category_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final isExpired = item.expiryTime.isBefore(now);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          Icon(
            _icons[item.category] ?? Icons.category_outlined,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              item.name,
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Chip(
            label: Text(
              '${item.weightKg.toStringAsFixed(1)} kg',
              style: textTheme.bodySmall,
            ),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: Spacing.xs),
          Chip(
            label: Text(
              isExpired ? 'Expired' : _formatExpiry(item.expiryTime, now),
              style: textTheme.bodySmall?.copyWith(
                color: isExpired ? Colors.red : cs.onSurface,
              ),
            ),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String _formatExpiry(DateTime expiry, DateTime now) {
    final diff = expiry.difference(now);
    if (diff.inHours < 24) return 'Expires in ${diff.inHours}h';
    return 'Expires ${_monthName(expiry.month)} ${expiry.day}';
  }

  String _monthName(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m];
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.batch});

  final Batch batch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final steps = [
      ('Created', batch.createdAt),
      ('Claimed', batch.claimedAt),
      ('Picked Up', batch.pickedUpAt),
      ('Delivered', batch.deliveredAt),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Spacing.sm),
            ...steps.map((step) => _TimelineRow(
              label: step.$1,
              timestamp: step.$2,
            )),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.label, required this.timestamp});

  final String label;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasValue = timestamp != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          Icon(
            hasValue ? Icons.circle : Icons.radio_button_unchecked,
            size: 12,
            color: hasValue ? cs.primary : cs.outline,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(label, style: textTheme.bodyMedium),
          ),
          Text(
            timestamp != null ? _formatTimestamp(timestamp!) : '—',
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} $h:$m';
  }
}

class _DriverSection extends StatelessWidget {
  const _DriverSection({required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Driver ID: $driverId',
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the widget tests**

```bash
cd apps/mobile && flutter test test/widget/features/donor/batch_detail_screen_test.dart
```

Expected: all 9 tests pass.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/donor/presentation/screens/batch_detail_screen.dart \
        apps/mobile/test/widget/features/donor/batch_detail_screen_test.dart
git commit -m "feat(donor): implement BatchDetailScreen with item list, timeline, and driver section"
```

---

## Task 9: Update Router + Dashboard `_BatchCard`

**Files:**
- Modify: `apps/mobile/lib/app/router.dart`
- Modify: `apps/mobile/lib/features/donor/presentation/screens/donor_dashboard_screen.dart`

- [ ] **Step 1: Update `router.dart`**

Add these two imports after the existing donor screen imports:

```dart
import 'package:saveameal/features/donor/presentation/screens/batch_detail_screen.dart';
import 'package:saveameal/features/donor/presentation/screens/donor_history_screen.dart';
```

Replace the flat `batch/:batchId/qr` route AND the batches stub with the new nested structure. Find these lines in the `/donor` routes block:

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

Also replace the batches stub:

```dart
          GoRoute(
            path: 'batches',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('All Batches'))),
          ),
```

With:

```dart
          GoRoute(
            path: 'batches',
            builder: (context, state) => const DonorHistoryScreen(),
          ),
```

- [ ] **Step 2: Update `_BatchCard` in `donor_dashboard_screen.dart`**

Read the full `_BatchCard` widget. It currently renders a `Card` with a `ListTile` that has an `IconButton` trailing for `open` status. Make two changes:
1. Wrap the `Card` in `InkWell` (or add `onTap` to the `Card`) to navigate to the detail screen
2. Remove the QR `IconButton` from the trailing

Find the `_BatchCard` class. Replace the `build` method body with:

```dart
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final shortId = batch.id.substring(0, 8).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: Card(
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
              child: Icon(
                Icons.inventory_2_outlined,
                color: cs.onSurfaceVariant,
              ),
            ),
            title: Text(
              'Batch #$shortId',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
  }
```

Keep the existing `_statusLabel` and `_formatDate` helper methods in `_BatchCard` unchanged.

- [ ] **Step 3: Update the existing dashboard widget test router** to match the new route structure

In `apps/mobile/test/widget/features/donor/donor_dashboard_screen_test.dart`, update `_buildRouter()` — replace the `batch/:batchId/qr` flat route with the nested structure:

```dart
GoRouter _buildRouter() => GoRouter(
  initialLocation: '/donor',
  routes: [
    GoRoute(
      path: '/donor',
      builder: (context, state) => const DonorDashboardScreen(),
      routes: [
        GoRoute(
          path: 'log',
          builder: (context, state) =>
              const Scaffold(body: Text('Log Batch Screen')),
        ),
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
        GoRoute(
          path: 'batches',
          builder: (context, state) =>
              const Scaffold(body: Text('All Batches Screen')),
        ),
        GoRoute(
          path: 'impact',
          builder: (context, state) =>
              const Scaffold(body: Text('Impact Screen')),
        ),
        GoRoute(
          path: 'account',
          builder: (context, state) =>
              const Scaffold(body: Text('Account Screen')),
        ),
      ],
    ),
  ],
);
```

- [ ] **Step 4: Run full test suite**

```bash
cd apps/mobile && flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Run static analysis + format**

```bash
cd apps/mobile && flutter analyze && dart format --set-exit-if-changed .
```

Expected: no issues, no formatting changes.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/app/router.dart \
        apps/mobile/lib/features/donor/presentation/screens/donor_dashboard_screen.dart \
        apps/mobile/test/widget/features/donor/donor_dashboard_screen_test.dart
git commit -m "feat(donor): wire batch detail + history routes; make dashboard cards tappable"
```

---

## Task 10: Final Verification

- [ ] **Step 1: Run the full test suite**

```bash
cd apps/mobile && flutter test --reporter=compact
```

Expected: all tests pass, 0 failures.

- [ ] **Step 2: Run static analysis**

```bash
cd apps/mobile && flutter analyze
```

Expected: No issues found.

- [ ] **Step 3: Run formatter**

```bash
cd apps/mobile && dart format --set-exit-if-changed .
```

Expected: 0 files changed.

- [ ] **Step 4: Run codegen check** (ensure no stale generated files)

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs
```

Expected: completes without errors.

- [ ] **Step 5: Write session log outcome**

Append to `docs/agent-log-kimtaeman.md`:

```
Outcome: Implemented DonorHistoryScreen and BatchDetailScreen. Added watchAllBatches + watchBatchById to all layers (FirestoreService → datasource → repository → use cases → providers). Batch entity extended with 3 timeline timestamps. Router restructured with batch/:batchId as parent of qr sub-route. Dashboard _BatchCard made tappable (card → detail) with QR button moved to detail screen AppBar.
Decisions: BatchModel already had claimedAt/pickedUpAt/deliveredAt — only Batch entity needed updating. Used client-side sort in datasource for watchAllBatches to avoid composite Firestore index. Filter chips implemented with local StatefulWidget state (no Riverpod needed for purely UI state). Dart 3 exhaustive switch expressions used for status/category mappings.
Handoff: QA-engineer to validate filter chips on device. Cloud Functions must write claimedAt/pickedUpAt/deliveredAt on status transitions for the timeline to show values (Flutter only reads these fields — it never writes them).
Review: PENDING
```
