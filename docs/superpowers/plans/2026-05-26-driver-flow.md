# Driver Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the full 7-screen driver flow for SaveAMeal — map discovery, job detail, en-route navigation, QR pickup verification, safety checklist + photo upload, delivery handover, and impact completion screen.

**Architecture:** Clean Architecture with domain use cases calling a `DriverRepository` interface; a single `DriverRemoteDatasourceImpl` handles all Firestore and Storage calls; a Riverpod `DriverNotifier` owns lifecycle state (step, phase, location timer) and is watched by all 7 screens.

**Tech Stack:** Flutter · Riverpod (codegen) · Freezed · GoRouter · Firebase Firestore · Firebase Storage · google_maps_flutter · geolocator · mobile_scanner · image_picker · qr_flutter

---

## File Map

| Action | Path |
|---|---|
| Create | `lib/core/exceptions/batch_exceptions.dart` |
| Modify | `lib/core/models/batch_model.dart` |
| Modify | `lib/core/models/user_model.dart` |
| Modify | `lib/services/firestore_service.dart` |
| Modify | `lib/services/storage_service.dart` |
| Create | `lib/features/driver/domain/repositories/driver_repository.dart` |
| Create | `lib/features/driver/domain/usecases/get_open_batches_usecase.dart` |
| Create | `lib/features/driver/domain/usecases/get_active_batch_usecase.dart` |
| Create | `lib/features/driver/domain/usecases/claim_batch_usecase.dart` |
| Create | `lib/features/driver/domain/usecases/confirm_pickup_usecase.dart` |
| Create | `lib/features/driver/domain/usecases/confirm_delivery_usecase.dart` |
| Create | `lib/features/driver/data/datasources/driver_remote_datasource.dart` |
| Create | `lib/features/driver/data/repositories/driver_repository_impl.dart` |
| Create | `lib/features/driver/presentation/providers/driver_state.dart` |
| Create | `lib/features/driver/presentation/providers/driver_notifier.dart` |
| Create | `lib/features/driver/presentation/providers/driver_provider.dart` |
| Modify | `lib/app/router.dart` |
| Replace | `lib/features/driver/presentation/screens/driver_map_screen.dart` |
| Create | `lib/features/driver/presentation/screens/job_detail_screen.dart` |
| Create | `lib/features/driver/presentation/screens/claim_rescue_screen.dart` |
| Create | `lib/features/driver/presentation/screens/pickup_verification_screen.dart` |
| Create | `lib/features/driver/presentation/screens/safety_verification_screen.dart` |
| Delete | `lib/features/driver/presentation/screens/pickup_screen.dart` |
| Delete | `lib/features/driver/presentation/screens/delivery_screen.dart` |
| Create | `lib/features/driver/presentation/screens/verify_delivery_screen.dart` |
| Create | `lib/features/driver/presentation/screens/delivery_completed_screen.dart` |
| Implement | `lib/features/donor/presentation/screens/batch_qr_screen.dart` |
| Create | `test/unit/driver/claim_batch_usecase_test.dart` |
| Create | `test/unit/driver/driver_notifier_test.dart` |
| Create | `test/widget/driver/driver_map_screen_test.dart` |
| Create | `test/widget/driver/job_detail_screen_test.dart` |
| Create | `test/widget/driver/claim_rescue_screen_test.dart` |
| Create | `test/widget/driver/pickup_verification_screen_test.dart` |
| Create | `test/widget/driver/safety_verification_screen_test.dart` |
| Create | `test/widget/driver/verify_delivery_screen_test.dart` |
| Create | `test/widget/driver/delivery_completed_screen_test.dart` |

All Flutter commands run from `apps/mobile/`. Use package imports (`package:saveameal/...`) everywhere.

---

## Task 1: Core exception + extend BatchModel

**Files:**
- Create: `lib/core/exceptions/batch_exceptions.dart`
- Modify: `lib/core/models/batch_model.dart`

- [ ] **Step 1: Create the exception class**

```dart
// lib/core/exceptions/batch_exceptions.dart
class BatchAlreadyClaimedException implements Exception {
  const BatchAlreadyClaimedException();
  @override
  String toString() => 'BatchAlreadyClaimedException: batch was already claimed';
}
```

- [ ] **Step 2: Add driver fields to BatchModel**

Replace the existing `BatchModel` class with:

```dart
// lib/core/models/batch_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:saveameal/core/models/batch_item_model.dart';

part 'batch_model.freezed.dart';
part 'batch_model.g.dart';

enum BatchStatus { open, claimed, pickedUp, delivered, closed }

@freezed
sealed class BatchModel with _$BatchModel {
  const factory BatchModel({
    required String id,
    required String donorId,
    @Default([]) List<BatchItemModel> items,
    required String pickupAddress,
    required BatchStatus status,
    String? driverId,
    String? beneficiaryId,
    // Denormalised beneficiary info (written at batch creation time)
    String? beneficiaryName,
    String? beneficiaryAddress,
    // Donor display info
    String? donorName,
    String? donorContact,
    // Scheduling
    String? pickupWindowStart,
    String? pickupWindowEnd,
    String? specialInstructions,
    // Lifecycle timestamps
    DateTime? claimedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    // Photos & QR
    String? photoUrl,
    String? pickupPhotoUrl,
    String? qrCode,
    // Delivery outcome
    String? deliveryNotes,
    int? rating,
    String? feedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _BatchModel;

  factory BatchModel.fromJson(Map<String, dynamic> json) =>
      _$BatchModelFromJson(json);
}
```

- [ ] **Step 3: Regenerate code**

```
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```

Expected: no errors. Files `batch_model.freezed.dart` and `batch_model.g.dart` regenerated.

- [ ] **Step 4: Commit**

```
git add apps/mobile/lib/core/exceptions/batch_exceptions.dart apps/mobile/lib/core/models/batch_model.dart apps/mobile/lib/core/models/batch_model.freezed.dart apps/mobile/lib/core/models/batch_model.g.dart
git commit -m "feat(driver): add BatchAlreadyClaimedException + extend BatchModel with driver fields"
```

---

## Task 2: Extend UserModel with points

**Files:**
- Modify: `lib/core/models/user_model.dart`

- [ ] **Step 1: Add points field**

In `lib/core/models/user_model.dart`, add `@Default(0) int points,` to the factory constructor, after `BeneficiaryStatus? status,`:

```dart
@freezed
sealed class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String name,
    required String email,
    required UserRole role,
    String? phone,
    String? orgName,
    BeneficiaryStatus? status,
    @Default(0) int points,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

- [ ] **Step 2: Regenerate**

```
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Commit**

```
git add apps/mobile/lib/core/models/user_model.dart apps/mobile/lib/core/models/user_model.freezed.dart apps/mobile/lib/core/models/user_model.g.dart
git commit -m "feat(driver): add points field to UserModel"
```

---

## Task 3: Implement FirestoreService driver methods

**Files:**
- Modify: `lib/services/firestore_service.dart`

The file already has stubs (`throw UnimplementedError()`). Replace them and add new methods.

- [ ] **Step 1: Replace `watchOpenBatches` stub**

```dart
Stream<List<BatchModel>> watchOpenBatches() => _db
    .collection(FirestoreConstants.batches)
    .where('status', isEqualTo: 'open')
    .snapshots()
    .map(
      (qs) => qs.docs
          .map((d) => BatchModel.fromJson({...d.data(), 'id': d.id}))
          .toList(),
    );
```

- [ ] **Step 2: Add `watchActiveBatchForDriver`**

```dart
Stream<BatchModel?> watchActiveBatchForDriver(String driverId) => _db
    .collection(FirestoreConstants.batches)
    .where('driverId', isEqualTo: driverId)
    .snapshots()
    .map((qs) {
      final active = qs.docs
          .map((d) => BatchModel.fromJson({...d.data(), 'id': d.id}))
          .where(
            (m) =>
                m.status == BatchStatus.claimed ||
                m.status == BatchStatus.pickedUp,
          )
          .toList();
      return active.isEmpty ? null : active.first;
    });
```

- [ ] **Step 3: Add `claimBatch` (Firestore transaction)**

```dart
Future<void> claimBatch(String batchId, String driverId) async {
  final ref = _db.collection(FirestoreConstants.batches).doc(batchId);
  await _db.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists || snap.data() == null) throw Exception('Batch not found');
    if (snap.data()!['status'] != 'open') {
      throw const BatchAlreadyClaimedException();
    }
    tx.update(ref, {
      'status': 'claimed',
      'driverId': driverId,
      'claimedAt': FieldValue.serverTimestamp(),
    });
  });
}
```

Add `import 'package:saveameal/core/exceptions/batch_exceptions.dart';` at the top of `firestore_service.dart`.

- [ ] **Step 4: Add `confirmPickup`**

```dart
Future<void> confirmPickup(String batchId, String pickupPhotoUrl) =>
    _db.collection(FirestoreConstants.batches).doc(batchId).update({
      'status': 'pickedUp',
      'pickedUpAt': FieldValue.serverTimestamp(),
      'pickupPhotoUrl': pickupPhotoUrl,
    });
```

- [ ] **Step 5: Add `confirmDelivery`**

```dart
Future<void> confirmDelivery(String batchId, String? notes) =>
    _db.collection(FirestoreConstants.batches).doc(batchId).update({
      'status': 'delivered',
      'deliveredAt': FieldValue.serverTimestamp(),
      if (notes != null && notes.isNotEmpty) 'deliveryNotes': notes,
    });
```

- [ ] **Step 6: Replace `upsertDriverLocation` stub**

```dart
Future<void> upsertDriverLocation(DriverLocationModel loc) => _db
    .collection(FirestoreConstants.driverLocations)
    .doc(loc.driverId)
    .set(loc.toJson());
```

- [ ] **Step 7: Add `watchUserPoints`**

```dart
Stream<int> watchUserPoints(String uid) => _db
    .collection(FirestoreConstants.users)
    .doc(uid)
    .snapshots()
    .map((ds) {
      if (!ds.exists || ds.data() == null) return 0;
      return (ds.data()!['points'] as int?) ?? 0;
    });
```

- [ ] **Step 8: Verify app still analyses cleanly**

```
flutter analyze
```

Expected: no new errors.

- [ ] **Step 9: Commit**

```
git add apps/mobile/lib/services/firestore_service.dart
git commit -m "feat(driver): implement driver Firestore methods (watchOpenBatches, claimBatch, confirmPickup, confirmDelivery, upsertDriverLocation, watchUserPoints)"
```

---

## Task 4: Extend StorageService with pickup photo upload

**Files:**
- Modify: `lib/services/storage_service.dart`

- [ ] **Step 1: Add upload method**

Append to `StorageService`:

```dart
Future<String> uploadPickupPhoto(String batchId, String localPath) async {
  final ref = _storage.ref().child('batch_photos/$batchId/pickup.jpg');
  await ref.putFile(File(localPath));
  return ref.getDownloadURL();
}
```

`File` is already imported via `dart:io` in this file.

- [ ] **Step 2: Commit**

```
git add apps/mobile/lib/services/storage_service.dart
git commit -m "feat(driver): add uploadPickupPhoto to StorageService"
```

---

## Task 5: Driver domain layer

**Files:**
- Create: `lib/features/driver/domain/repositories/driver_repository.dart`
- Create: `lib/features/driver/domain/usecases/get_open_batches_usecase.dart`
- Create: `lib/features/driver/domain/usecases/get_active_batch_usecase.dart`
- Create: `lib/features/driver/domain/usecases/claim_batch_usecase.dart`
- Create: `lib/features/driver/domain/usecases/confirm_pickup_usecase.dart`
- Create: `lib/features/driver/domain/usecases/confirm_delivery_usecase.dart`

- [ ] **Step 1: Write failing unit test for ClaimBatchUsecase**

```dart
// test/unit/driver/claim_batch_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/core/exceptions/batch_exceptions.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/domain/usecases/claim_batch_usecase.dart';

class _FakeDriverRepository implements DriverRepository {
  bool shouldThrow = false;
  String? lastClaimedBatchId;
  String? lastClaimedDriverId;

  @override
  Future<void> claimBatch(String batchId, String driverId) async {
    if (shouldThrow) throw const BatchAlreadyClaimedException();
    lastClaimedBatchId = batchId;
    lastClaimedDriverId = driverId;
  }

  @override
  Stream<List<BatchSummary>> getOpenBatches() => const Stream.empty();

  @override
  Stream<BatchSummary?> getActiveBatch(String driverId) => const Stream.empty();

  @override
  Future<void> confirmPickup(String batchId, String photoUrl) async {}

  @override
  Future<void> confirmDelivery(String batchId, String? notes) async {}

  @override
  Future<void> upsertLocation(String driverId, double lat, double lng) async {}

  @override
  Stream<int> watchPoints(String uid) => const Stream.empty();
}

void main() {
  late _FakeDriverRepository repo;
  late ClaimBatchUsecase usecase;

  setUp(() {
    repo = _FakeDriverRepository();
    usecase = ClaimBatchUsecase(repo);
  });

  test('calls repository with correct batchId and driverId', () async {
    await usecase('batch-1', 'driver-1');
    expect(repo.lastClaimedBatchId, 'batch-1');
    expect(repo.lastClaimedDriverId, 'driver-1');
  });

  test('propagates BatchAlreadyClaimedException', () async {
    repo.shouldThrow = true;
    expect(
      () => usecase('batch-1', 'driver-1'),
      throwsA(isA<BatchAlreadyClaimedException>()),
    );
  });
}
```

- [ ] **Step 2: Run test — expect compile failure (classes don't exist yet)**

```
cd apps/mobile && flutter test test/unit/driver/claim_batch_usecase_test.dart
```

Expected: compilation error — `DriverRepository` and `ClaimBatchUsecase` not found.

- [ ] **Step 3: Create DriverRepository interface**

```dart
// lib/features/driver/domain/repositories/driver_repository.dart

// Pure Dart — no Flutter or Firebase imports.
import 'package:saveameal/core/models/batch_model.dart';

// Lightweight summary for map display (avoids exposing full BatchModel to domain).
class BatchSummary {
  const BatchSummary({
    required this.id,
    required this.donorName,
    required this.pickupAddress,
    required this.beneficiaryAddress,
    required this.beneficiaryName,
    required this.totalPortions,
    required this.lat,
    required this.lng,
    required this.foodCategory,
    this.pickupWindowStart,
    this.pickupWindowEnd,
    this.specialInstructions,
    this.donorContact,
    this.items = const [],
  });

  final String id;
  final String donorName;
  final String pickupAddress;
  final String beneficiaryAddress;
  final String beneficiaryName;
  final int totalPortions;
  final double lat;
  final double lng;
  final String foodCategory;
  final String? pickupWindowStart;
  final String? pickupWindowEnd;
  final String? specialInstructions;
  final String? donorContact;
  final List<BatchItemModel> items;
}

abstract class DriverRepository {
  Stream<List<BatchSummary>> getOpenBatches();
  Stream<BatchSummary?> getActiveBatch(String driverId);
  Future<void> claimBatch(String batchId, String driverId);
  Future<void> confirmPickup(String batchId, String photoUrl);
  Future<void> confirmDelivery(String batchId, String? notes);
  Future<void> upsertLocation(String driverId, double lat, double lng);
  Stream<int> watchPoints(String uid);
}
```

Wait — `BatchItemModel` is a data-layer type. Replace with a domain entity import or just expose the fields needed. For simplicity in this codebase (which already uses `BatchModel` across layers), import it:

```dart
// lib/features/driver/domain/repositories/driver_repository.dart
import 'package:saveameal/core/models/batch_item_model.dart';
```

- [ ] **Step 4: Create use cases**

```dart
// lib/features/driver/domain/usecases/claim_batch_usecase.dart
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class ClaimBatchUsecase {
  const ClaimBatchUsecase(this._repository);
  final DriverRepository _repository;
  Future<void> call(String batchId, String driverId) =>
      _repository.claimBatch(batchId, driverId);
}
```

```dart
// lib/features/driver/domain/usecases/get_open_batches_usecase.dart
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class GetOpenBatchesUsecase {
  const GetOpenBatchesUsecase(this._repository);
  final DriverRepository _repository;
  Stream<List<BatchSummary>> call() => _repository.getOpenBatches();
}
```

```dart
// lib/features/driver/domain/usecases/get_active_batch_usecase.dart
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class GetActiveBatchUsecase {
  const GetActiveBatchUsecase(this._repository);
  final DriverRepository _repository;
  Stream<BatchSummary?> call(String driverId) =>
      _repository.getActiveBatch(driverId);
}
```

```dart
// lib/features/driver/domain/usecases/confirm_pickup_usecase.dart
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class ConfirmPickupUsecase {
  const ConfirmPickupUsecase(this._repository);
  final DriverRepository _repository;
  Future<void> call(String batchId, String photoUrl) =>
      _repository.confirmPickup(batchId, photoUrl);
}
```

```dart
// lib/features/driver/domain/usecases/confirm_delivery_usecase.dart
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class ConfirmDeliveryUsecase {
  const ConfirmDeliveryUsecase(this._repository);
  final DriverRepository _repository;
  Future<void> call(String batchId, String? notes) =>
      _repository.confirmDelivery(batchId, notes);
}
```

- [ ] **Step 5: Run unit test — expect pass**

```
flutter test test/unit/driver/claim_batch_usecase_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 6: Commit**

```
git add apps/mobile/lib/features/driver/domain/ apps/mobile/test/unit/driver/claim_batch_usecase_test.dart
git commit -m "feat(driver): add domain layer — DriverRepository interface + 5 use cases"
```

---

## Task 6: Driver data layer

**Files:**
- Create: `lib/features/driver/data/datasources/driver_remote_datasource.dart`
- Create: `lib/features/driver/data/repositories/driver_repository_impl.dart`

- [ ] **Step 1: Create DriverRemoteDatasource**

```dart
// lib/features/driver/data/datasources/driver_remote_datasource.dart
import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/core/models/driver_location_model.dart';
import 'package:saveameal/services/firestore_service.dart';
import 'package:saveameal/services/storage_service.dart';

abstract class DriverRemoteDatasource {
  Stream<List<BatchModel>> watchOpenBatches();
  Stream<BatchModel?> watchActiveBatch(String driverId);
  Future<void> claimBatch(String batchId, String driverId);
  Future<void> confirmPickup(String batchId, String pickupPhotoUrl);
  Future<void> confirmDelivery(String batchId, String? notes);
  Future<void> upsertLocation(String driverId, double lat, double lng);
  Future<String> uploadPickupPhoto(String batchId, String localPath);
  Stream<int> watchPoints(String uid);
}

class DriverRemoteDatasourceImpl implements DriverRemoteDatasource {
  const DriverRemoteDatasourceImpl(this._firestore, this._storage);

  final FirestoreService _firestore;
  final StorageService _storage;

  @override
  Stream<List<BatchModel>> watchOpenBatches() =>
      _firestore.watchOpenBatches();

  @override
  Stream<BatchModel?> watchActiveBatch(String driverId) =>
      _firestore.watchActiveBatchForDriver(driverId);

  @override
  Future<void> claimBatch(String batchId, String driverId) =>
      _firestore.claimBatch(batchId, driverId);

  @override
  Future<void> confirmPickup(String batchId, String pickupPhotoUrl) =>
      _firestore.confirmPickup(batchId, pickupPhotoUrl);

  @override
  Future<void> confirmDelivery(String batchId, String? notes) =>
      _firestore.confirmDelivery(batchId, notes);

  @override
  Future<void> upsertLocation(String driverId, double lat, double lng) =>
      _firestore.upsertDriverLocation(
        DriverLocationModel(driverId: driverId, lat: lat, lng: lng),
      );

  @override
  Future<String> uploadPickupPhoto(String batchId, String localPath) =>
      _storage.uploadPickupPhoto(batchId, localPath);

  @override
  Stream<int> watchPoints(String uid) => _firestore.watchUserPoints(uid);
}
```

- [ ] **Step 2: Create DriverRepositoryImpl**

```dart
// lib/features/driver/data/repositories/driver_repository_impl.dart
import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class DriverRepositoryImpl implements DriverRepository {
  const DriverRepositoryImpl(this._datasource);

  final DriverRemoteDatasource _datasource;

  @override
  Stream<List<BatchSummary>> getOpenBatches() =>
      _datasource.watchOpenBatches().map(
        (models) => models.map(_toSummary).whereType<BatchSummary>().toList(),
      );

  @override
  Stream<BatchSummary?> getActiveBatch(String driverId) =>
      _datasource.watchActiveBatch(driverId).map(
        (m) => m != null ? _toSummary(m) : null,
      );

  @override
  Future<void> claimBatch(String batchId, String driverId) =>
      _datasource.claimBatch(batchId, driverId);

  @override
  Future<void> confirmPickup(String batchId, String photoUrl) =>
      _datasource.confirmPickup(batchId, photoUrl);

  @override
  Future<void> confirmDelivery(String batchId, String? notes) =>
      _datasource.confirmDelivery(batchId, notes);

  @override
  Future<void> upsertLocation(String driverId, double lat, double lng) =>
      _datasource.upsertLocation(driverId, lat, lng);

  @override
  Stream<int> watchPoints(String uid) => _datasource.watchPoints(uid);

  // Map BatchModel → BatchSummary. Returns null if coordinates missing.
  BatchSummary? _toSummary(BatchModel m) {
    // lat/lng: stored in Firestore but not yet on BatchModel.
    // For now, parse from pickupAddress or default to Bangkok centre.
    // TODO: add lat/lng fields to BatchModel in a future task.
    return BatchSummary(
      id: m.id,
      donorName: m.donorName ?? 'Donor',
      pickupAddress: m.pickupAddress,
      beneficiaryAddress: m.beneficiaryAddress ?? '',
      beneficiaryName: m.beneficiaryName ?? '',
      totalPortions: m.items.length,
      lat: 13.7563,   // placeholder — Bangkok centre
      lng: 100.5018,
      foodCategory: m.items.isNotEmpty ? m.items.first.category : 'local_dining',
      pickupWindowStart: m.pickupWindowStart,
      pickupWindowEnd: m.pickupWindowEnd,
      specialInstructions: m.specialInstructions,
      donorContact: m.donorContact,
      items: m.items,
    );
  }
}
```

> **Note:** `lat`/`lng` are placeholder values (Bangkok centre) until a geocoding step is added to the donor log-batch flow. This is logged in the spec's out-of-scope section.

- [ ] **Step 3: Verify analysis**

```
flutter analyze
```

Expected: no errors.

- [ ] **Step 4: Commit**

```
git add apps/mobile/lib/features/driver/data/
git commit -m "feat(driver): add data layer — DriverRemoteDatasourceImpl + DriverRepositoryImpl"
```

---

## Task 7: Driver Riverpod providers and DriverNotifier

**Files:**
- Create: `lib/features/driver/presentation/providers/driver_state.dart`
- Create: `lib/features/driver/presentation/providers/driver_notifier.dart`
- Create: `lib/features/driver/presentation/providers/driver_provider.dart`

- [ ] **Step 1: Write failing notifier unit test**

```dart
// test/unit/driver/driver_notifier_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/core/exceptions/batch_exceptions.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';

class _FakeRepo implements DriverRepository {
  bool claimShouldThrow = false;
  String? lastConfirmedPickup;
  String? lastConfirmedDelivery;

  @override
  Future<void> claimBatch(String batchId, String driverId) async {
    if (claimShouldThrow) throw const BatchAlreadyClaimedException();
  }

  @override
  Future<void> confirmPickup(String batchId, String photoUrl) async {
    lastConfirmedPickup = batchId;
  }

  @override
  Future<void> confirmDelivery(String batchId, String? notes) async {
    lastConfirmedDelivery = batchId;
  }

  @override
  Stream<List<BatchSummary>> getOpenBatches() => const Stream.empty();

  @override
  Stream<BatchSummary?> getActiveBatch(String driverId) => const Stream.empty();

  @override
  Future<void> upsertLocation(String driverId, double lat, double lng) async {}

  @override
  Stream<int> watchPoints(String uid) => const Stream.empty();
}

ProviderContainer _makeContainer(_FakeRepo repo) {
  return ProviderContainer(
    overrides: [driverRepositoryProvider.overrideWithValue(repo)],
  );
}

void main() {
  test('initial state is browsing', () {
    final container = _makeContainer(_FakeRepo());
    final state = container.read(driverNotifierProvider);
    expect(state.step, DriverStep.browsing);
  });

  test('claimBatch transitions step to claimed', () async {
    final container = _makeContainer(_FakeRepo());
    await container.read(driverNotifierProvider.notifier).claimBatch('b1', 'd1');
    expect(container.read(driverNotifierProvider).step, DriverStep.claimed);
  });

  test('claimBatch with conflict rethrows BatchAlreadyClaimedException', () async {
    final repo = _FakeRepo()..claimShouldThrow = true;
    final container = _makeContainer(repo);
    expect(
      () => container.read(driverNotifierProvider.notifier).claimBatch('b1', 'd1'),
      throwsA(isA<BatchAlreadyClaimedException>()),
    );
  });

  test('confirmDelivery transitions step to delivered', () async {
    final container = _makeContainer(_FakeRepo());
    final notifier = container.read(driverNotifierProvider.notifier);
    await notifier.claimBatch('b1', 'd1');
    await notifier.confirmPickup('b1', '/fake/path.jpg');
    await notifier.confirmDelivery('b1', null);
    expect(container.read(driverNotifierProvider).step, DriverStep.delivered);
  });
}
```

- [ ] **Step 2: Run test — expect compile failure**

```
flutter test test/unit/driver/driver_notifier_test.dart
```

Expected: compilation error.

- [ ] **Step 3: Create DriverState**

```dart
// lib/features/driver/presentation/providers/driver_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

part 'driver_state.freezed.dart';

enum DriverStep { browsing, claimed, pickedUp, delivered }

enum ClaimRescuePhase { enRoutePickup, enRouteBeneficiary }

@freezed
class DriverState with _$DriverState {
  const factory DriverState({
    BatchSummary? activeBatch,
    BatchSummary? selectedBatch,
    @Default(DriverStep.browsing) DriverStep step,
    @Default(ClaimRescuePhase.enRoutePickup) ClaimRescuePhase rescuePhase,
  }) = _DriverState;
}
```

Run codegen:
```
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: Create DriverNotifier**

```dart
// lib/features/driver/presentation/providers/driver_notifier.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/core/logging/app_logger.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';

part 'driver_notifier.g.dart';

@riverpod
class DriverNotifier extends _$DriverNotifier {
  Timer? _locationTimer;

  @override
  DriverState build() {
    ref.onDispose(_stopTracking);
    return const DriverState();
  }

  void selectBatch(BatchSummary batch) {
    state = state.copyWith(selectedBatch: batch);
  }

  void clearSelection() {
    state = state.copyWith(selectedBatch: null);
  }

  Future<void> claimBatch(String batchId, String driverId) async {
    await ref.read(driverRepositoryProvider).claimBatch(batchId, driverId);
    state = state.copyWith(
      step: DriverStep.claimed,
      rescuePhase: ClaimRescuePhase.enRoutePickup,
      selectedBatch: null,
    );
    _startTracking(driverId);
  }

  Future<void> confirmPickup(String batchId, String localPhotoPath) async {
    final repo = ref.read(driverRepositoryProvider);
    final photoUrl = await ref
        .read(driverRemoteDatasourceProvider)
        .uploadPickupPhoto(batchId, localPhotoPath);
    await repo.confirmPickup(batchId, photoUrl);
    state = state.copyWith(
      step: DriverStep.pickedUp,
      rescuePhase: ClaimRescuePhase.enRouteBeneficiary,
    );
  }

  Future<void> confirmDelivery(String batchId, String? notes) async {
    await ref.read(driverRepositoryProvider).confirmDelivery(batchId, notes);
    _stopTracking();
    state = state.copyWith(step: DriverStep.delivered);
  }

  void resetToIdle() {
    state = const DriverState();
  }

  void _startTracking(String driverId) {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await ref
            .read(driverRepositoryProvider)
            .upsertLocation(driverId, pos.latitude, pos.longitude);
      } catch (e) {
        AppLogger.warning('Location write failed', error: e);
      }
    });
  }

  void _stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }
}
```

- [ ] **Step 5: Create driver_provider.dart**

```dart
// lib/features/driver/presentation/providers/driver_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:saveameal/features/driver/data/repositories/driver_repository_impl.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/domain/usecases/get_active_batch_usecase.dart';
import 'package:saveameal/features/driver/domain/usecases/get_open_batches_usecase.dart';
import 'package:saveameal/services/service_providers.dart';

part 'driver_provider.g.dart';

@riverpod
DriverRemoteDatasource driverRemoteDatasource(Ref ref) =>
    DriverRemoteDatasourceImpl(
      ref.watch(firestoreServiceProvider),
      ref.watch(storageServiceProvider),
    );

@riverpod
DriverRepository driverRepository(Ref ref) =>
    DriverRepositoryImpl(ref.watch(driverRemoteDatasourceProvider));

@riverpod
GetOpenBatchesUsecase getOpenBatchesUsecase(Ref ref) =>
    GetOpenBatchesUsecase(ref.watch(driverRepositoryProvider));

@riverpod
GetActiveBatchUsecase getActiveBatchUsecase(Ref ref) =>
    GetActiveBatchUsecase(ref.watch(driverRepositoryProvider));

@riverpod
Stream<List<BatchSummary>> openBatches(Ref ref) =>
    ref.watch(getOpenBatchesUsecaseProvider).call();

@riverpod
Stream<BatchSummary?> activeBatchForDriver(Ref ref, String driverId) =>
    ref.watch(getActiveBatchUsecaseProvider).call(driverId);
```

- [ ] **Step 6: Run codegen**

```
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Run unit tests — expect pass**

```
flutter test test/unit/driver/driver_notifier_test.dart test/unit/driver/claim_batch_usecase_test.dart
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

```
git add apps/mobile/lib/features/driver/presentation/providers/ apps/mobile/test/unit/driver/
git commit -m "feat(driver): add DriverState, DriverNotifier, and Riverpod providers"
```

---

## Task 8: Update router with driver sub-routes

**Files:**
- Modify: `lib/app/router.dart`

- [ ] **Step 1: Add imports for new screens (add them now even though screens are stubs — they'll be replaced in later tasks)**

Add to imports at top of `lib/app/router.dart`:

```dart
import 'package:saveameal/features/driver/presentation/screens/claim_rescue_screen.dart';
import 'package:saveameal/features/driver/presentation/screens/delivery_completed_screen.dart';
import 'package:saveameal/features/driver/presentation/screens/job_detail_screen.dart';
import 'package:saveameal/features/driver/presentation/screens/pickup_verification_screen.dart';
import 'package:saveameal/features/driver/presentation/screens/safety_verification_screen.dart';
import 'package:saveameal/features/driver/presentation/screens/verify_delivery_screen.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
```

- [ ] **Step 2: Replace the `/driver` GoRoute with nested sub-routes**

Replace:
```dart
GoRoute(
  path: '/driver',
  builder: (context, state) => const DriverMapScreen(),
),
```

With:
```dart
GoRoute(
  path: '/driver',
  builder: (context, state) => const DriverMapScreen(),
  routes: [
    GoRoute(
      path: 'job/:batchId',
      builder: (context, state) => JobDetailScreen(
        batch: state.extra! as BatchSummary,
      ),
    ),
    GoRoute(
      path: 'rescue',
      builder: (context, state) => const ClaimRescueScreen(),
    ),
    GoRoute(
      path: 'pickup-verify',
      builder: (context, state) => const PickupVerificationScreen(),
    ),
    GoRoute(
      path: 'safety',
      builder: (context, state) => const SafetyVerificationScreen(),
    ),
    GoRoute(
      path: 'verify-delivery',
      builder: (context, state) => const VerifyDeliveryScreen(),
    ),
    GoRoute(
      path: 'completed',
      builder: (context, state) => const DeliveryCompletedScreen(),
    ),
  ],
),
```

- [ ] **Step 3: Create stub screens so the import compiles**

Create each new screen as a minimal stub (identical pattern to existing stubs):

```dart
// lib/features/driver/presentation/screens/job_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.batch});
  final BatchSummary batch;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('TODO: JobDetailScreen')));
}
```

```dart
// lib/features/driver/presentation/screens/claim_rescue_screen.dart
import 'package:flutter/material.dart';
class ClaimRescueScreen extends StatelessWidget {
  const ClaimRescueScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('TODO: ClaimRescueScreen')));
}
```

```dart
// lib/features/driver/presentation/screens/pickup_verification_screen.dart
import 'package:flutter/material.dart';
class PickupVerificationScreen extends StatelessWidget {
  const PickupVerificationScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('TODO: PickupVerificationScreen')));
}
```

```dart
// lib/features/driver/presentation/screens/safety_verification_screen.dart
import 'package:flutter/material.dart';
class SafetyVerificationScreen extends StatelessWidget {
  const SafetyVerificationScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('TODO: SafetyVerificationScreen')));
}
```

```dart
// lib/features/driver/presentation/screens/verify_delivery_screen.dart
import 'package:flutter/material.dart';
class VerifyDeliveryScreen extends StatelessWidget {
  const VerifyDeliveryScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('TODO: VerifyDeliveryScreen')));
}
```

```dart
// lib/features/driver/presentation/screens/delivery_completed_screen.dart
import 'package:flutter/material.dart';
class DeliveryCompletedScreen extends StatelessWidget {
  const DeliveryCompletedScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('TODO: DeliveryCompletedScreen')));
}
```

- [ ] **Step 4: Delete dead stubs**

```
git rm apps/mobile/lib/features/driver/presentation/screens/pickup_screen.dart
git rm apps/mobile/lib/features/driver/presentation/screens/delivery_screen.dart
```

- [ ] **Step 5: Verify analysis**

```
flutter analyze
```

Expected: no errors.

- [ ] **Step 6: Commit**

```
git add apps/mobile/lib/app/router.dart apps/mobile/lib/features/driver/presentation/screens/
git commit -m "feat(driver): add driver sub-routes to router + stub screens + remove dead pickup/delivery stubs"
```

---

## Task 9: DriverMapScreen

**Files:**
- Replace: `lib/features/driver/presentation/screens/driver_map_screen.dart`
- Create: `test/widget/driver/driver_map_screen_test.dart`

- [ ] **Step 1: Write widget test first**

```dart
// test/widget/driver/driver_map_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/features/driver/presentation/screens/driver_map_screen.dart';

class _FakeNotifier extends DriverNotifier {
  @override
  DriverState build() => const DriverState();
  @override
  void selectBatch(batch) => state = state.copyWith(selectedBatch: batch);
}

Widget _wrap(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('shows map placeholder and no preview card by default',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const DriverMapScreen(),
        overrides: [
          openBatchesProvider.overrideWith((_) => const Stream.empty()),
          driverNotifierProvider.overrideWith(() => _FakeNotifier()),
        ],
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('driver_map')), findsOneWidget);
    expect(find.byKey(const Key('batch_preview_card')), findsNothing);
  });

  testWidgets('shows preview card when selectedBatch is set', (tester) async {
    final notifier = _FakeNotifier();
    await tester.pumpWidget(
      _wrap(
        const DriverMapScreen(),
        overrides: [
          openBatchesProvider.overrideWith((_) => const Stream.empty()),
          driverNotifierProvider.overrideWith(() => notifier),
        ],
      ),
    );
    const fakeBatch = BatchSummary(
      id: 'b1',
      donorName: 'Central Bakery',
      pickupAddress: '123 Baker St',
      beneficiaryAddress: '456 Shelter Rd',
      beneficiaryName: 'Haven Shelter',
      totalPortions: 38,
      lat: 13.7,
      lng: 100.5,
      foodCategory: 'local_pizza',
    );
    notifier.selectBatch(fakeBatch);
    await tester.pump();
    expect(find.byKey(const Key('batch_preview_card')), findsOneWidget);
    expect(find.text('Central Bakery'), findsOneWidget);
    expect(find.text('View Job →'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test — expect fail**

```
flutter test test/widget/driver/driver_map_screen_test.dart
```

Expected: FAIL — `Key('driver_map')` not found.

- [ ] **Step 3: Implement DriverMapScreen**

```dart
// lib/features/driver/presentation/screens/driver_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class DriverMapScreen extends ConsumerWidget {
  const DriverMapScreen({super.key});

  static const _bangkokCenter = CameraPosition(
    target: LatLng(13.7563, 100.5018),
    zoom: 13,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverState = ref.watch(driverNotifierProvider);
    final batchesAsync = ref.watch(openBatchesProvider);
    final batches = batchesAsync.asData?.value ?? [];
    final markers = _buildMarkers(batches, ref);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            key: const Key('driver_map'),
            initialCameraPosition: _bangkokCenter,
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          if (driverState.selectedBatch != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _BatchPreviewCard(
                batch: driverState.selectedBatch!,
                onViewJob: () => context.push(
                  '/driver/job/${driverState.selectedBatch!.id}',
                  extra: driverState.selectedBatch,
                ),
                onDismiss: () =>
                    ref.read(driverNotifierProvider.notifier).clearSelection(),
              ),
            ),
          _DriverBottomNav(currentIndex: 0),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(List<BatchSummary> batches, WidgetRef ref) {
    return {
      for (final batch in batches)
        Marker(
          markerId: MarkerId(batch.id),
          position: LatLng(batch.lat, batch.lng),
          onTap: () =>
              ref.read(driverNotifierProvider.notifier).selectBatch(batch),
        ),
    };
  }
}

class _BatchPreviewCard extends StatelessWidget {
  const _BatchPreviewCard({
    required this.batch,
    required this.onViewJob,
    required this.onDismiss,
  });

  final BatchSummary batch;
  final VoidCallback onViewJob;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Container(
        key: const Key('batch_preview_card'),
        margin: const EdgeInsets.all(Spacing.md),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AVAILABLE PICKUP',
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(batch.donorName, style: textTheme.titleMedium),
                      Text(
                        batch.pickupAddress,
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${batch.totalPortions}\nitems',
                    style: textTheme.labelSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            if (batch.pickupWindowStart != null)
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    '${batch.pickupWindowStart} – ${batch.pickupWindowEnd}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            const SizedBox(height: Spacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onViewJob,
                child: const Text('View Job →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverBottomNav extends StatelessWidget {
  const _DriverBottomNav({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.eco), label: 'Impact'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
        onTap: (i) {
          if (i == 0) context.go('/driver');
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```
flutter test test/widget/driver/driver_map_screen_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 5: Commit**

```
git add apps/mobile/lib/features/driver/presentation/screens/driver_map_screen.dart apps/mobile/test/widget/driver/driver_map_screen_test.dart
git commit -m "feat(driver): implement DriverMapScreen with GoogleMap markers and batch preview card"
```

---

## Task 10: JobDetailScreen

**Files:**
- Replace stub: `lib/features/driver/presentation/screens/job_detail_screen.dart`
- Create: `test/widget/driver/job_detail_screen_test.dart`

- [ ] **Step 1: Write widget test**

```dart
// test/widget/driver/job_detail_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/features/driver/presentation/screens/job_detail_screen.dart';

const _fakeBatch = BatchSummary(
  id: 'b1',
  donorName: 'Central Bakery',
  pickupAddress: '123 Baker St, City Center',
  beneficiaryAddress: '1200 Greenway Blvd',
  beneficiaryName: 'Haven Shelter',
  totalPortions: 38,
  lat: 13.7,
  lng: 100.5,
  foodCategory: 'local_pizza',
  specialInstructions: 'Park at rear',
);

class _NoopNotifier extends DriverNotifier {
  @override
  DriverState build() => const DriverState();
}

Widget _wrap(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('renders pickup and dropoff addresses', (tester) async {
    await tester.pumpWidget(
      _wrap(
        JobDetailScreen(batch: _fakeBatch),
        overrides: [driverNotifierProvider.overrideWith(() => _NoopNotifier())],
      ),
    );
    expect(find.text('123 Baker St, City Center'), findsOneWidget);
    expect(find.text('1200 Greenway Blvd'), findsOneWidget);
    expect(find.text('Haven Shelter'), findsOneWidget);
    expect(find.text('Park at rear'), findsOneWidget);
    expect(find.text('Accept Job'), findsOneWidget);
  });

  testWidgets('Accept Job button is present and tappable', (tester) async {
    await tester.pumpWidget(
      _wrap(
        JobDetailScreen(batch: _fakeBatch),
        overrides: [driverNotifierProvider.overrideWith(() => _NoopNotifier())],
      ),
    );
    expect(find.text('Accept Job'), findsOneWidget);
    // Button exists — navigation is tested via integration test
  });
}
```

- [ ] **Step 2: Run test — expect fail**

```
flutter test test/widget/driver/job_detail_screen_test.dart
```

Expected: FAIL — stub shows "TODO" text, address finders return nothing.

- [ ] **Step 3: Implement JobDetailScreen**

```dart
// lib/features/driver/presentation/screens/job_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/core/exceptions/batch_exceptions.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.batch});

  final BatchSummary batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Details'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: Spacing.md),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Available',
              style: textTheme.labelSmall?.copyWith(
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          _InfoCard(children: [
            _AddressRow(
              icon: Icons.storefront,
              label: 'PICKUP FROM',
              name: batch.donorName,
              address: batch.pickupAddress,
            ),
            const Divider(height: 1),
            _AddressRow(
              icon: Icons.volunteer_activism,
              label: 'DROP-OFF TO',
              name: batch.beneficiaryName,
              address: batch.beneficiaryAddress,
            ),
          ]),
          const SizedBox(height: Spacing.md),
          _InfoCard(children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DETAILS', style: textTheme.labelSmall),
                  const SizedBox(height: Spacing.sm),
                  if (batch.pickupWindowStart != null)
                    _DetailRow(
                      icon: Icons.schedule,
                      text: 'Today, ${batch.pickupWindowStart} – ${batch.pickupWindowEnd}',
                    ),
                  if (batch.specialInstructions != null)
                    _DetailRow(
                      icon: Icons.info_outline,
                      text: batch.specialInstructions!,
                    ),
                  if (batch.donorContact != null)
                    _DetailRow(
                      icon: Icons.person_outline,
                      text: batch.donorContact!,
                    ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: Spacing.md),
          _InfoCard(children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Batch Summary', style: textTheme.titleSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                          vertical: Spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${batch.totalPortions} Portions',
                          style: textTheme.labelSmall?.copyWith(
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.xs,
                    runSpacing: Spacing.xs,
                    children: batch.items
                        .map(
                          (item) => Chip(
                            label: Text(
                              '${item.name}',
                              style: textTheme.labelSmall,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: Spacing.xl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: FilledButton(
            onPressed: () => _onAccept(context, ref),
            child: const Text('Accept Job'),
          ),
        ),
      ),
    );
  }

  Future<void> _onAccept(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
    try {
      await ref.read(driverNotifierProvider.notifier).claimBatch(batch.id, uid);
      if (context.mounted) context.go('/driver/rescue');
    } on BatchAlreadyClaimedException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch already taken — try another.')),
        );
        context.pop();
      }
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(children: children),
      );
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.icon,
    required this.label,
    required this.name,
    required this.address,
  });
  final IconData icon;
  final String label;
  final String name;
  final String address;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(color: cs.primary),
                ),
                Text(name, style: textTheme.bodyMedium),
                Text(
                  address,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: Spacing.xs),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```
flutter test test/widget/driver/job_detail_screen_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 5: Commit**

```
git add apps/mobile/lib/features/driver/presentation/screens/job_detail_screen.dart apps/mobile/test/widget/driver/job_detail_screen_test.dart
git commit -m "feat(driver): implement JobDetailScreen with pickup/dropoff details and Accept Job CTA"
```

---

## Task 11: ClaimRescueScreen

**Files:**
- Replace stub: `lib/features/driver/presentation/screens/claim_rescue_screen.dart`
- Create: `test/widget/driver/claim_rescue_screen_test.dart`

- [ ] **Step 1: Write widget test**

```dart
// test/widget/driver/claim_rescue_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/features/driver/presentation/screens/claim_rescue_screen.dart';

const _fakeBatch = BatchSummary(
  id: 'b1',
  donorName: 'Central Bakery',
  pickupAddress: '123 Baker St',
  beneficiaryAddress: '1200 Greenway Blvd',
  beneficiaryName: 'Haven Shelter',
  totalPortions: 38,
  lat: 13.7,
  lng: 100.5,
  foodCategory: 'local_pizza',
);

Widget _wrap(DriverState state) {
  final notifier = _FakeNotifier(state);
  return ProviderScope(
    overrides: [
      driverNotifierProvider.overrideWith(() => notifier),
      activeBatchForDriverProvider('uid').overrideWith((_) =>
          Stream.value(_fakeBatch)),
    ],
    child: const MaterialApp(home: ClaimRescueScreen()),
  );
}

class _FakeNotifier extends DriverNotifier {
  _FakeNotifier(DriverState initial) : _initial = initial;
  final DriverState _initial;
  @override
  DriverState build() => _initial;
}

void main() {
  testWidgets('en_route_pickup shows donor address and Arrived at Pick-up',
      (tester) async {
    await tester.pumpWidget(_wrap(const DriverState(
      step: DriverStep.claimed,
      rescuePhase: ClaimRescuePhase.enRoutePickup,
    )));
    await tester.pump();
    expect(find.text('123 Baker St'), findsOneWidget);
    expect(find.text('Arrived at Pick-up'), findsOneWidget);
    expect(find.text('Arrived at Beneficiary'), findsNothing);
  });

  testWidgets('en_route_beneficiary shows beneficiary address',
      (tester) async {
    await tester.pumpWidget(_wrap(const DriverState(
      step: DriverStep.pickedUp,
      rescuePhase: ClaimRescuePhase.enRouteBeneficiary,
    )));
    await tester.pump();
    expect(find.text('1200 Greenway Blvd'), findsOneWidget);
    expect(find.text('Arrived at Beneficiary'), findsOneWidget);
    expect(find.text('Arrived at Pick-up'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test — expect fail**

```
flutter test test/widget/driver/claim_rescue_screen_test.dart
```

- [ ] **Step 3: Implement ClaimRescueScreen**

```dart
// lib/features/driver/presentation/screens/claim_rescue_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class ClaimRescueScreen extends ConsumerWidget {
  const ClaimRescueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverState = ref.watch(driverNotifierProvider);
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final batchAsync = ref.watch(activeBatchForDriverProvider(uid));
    final batch = batchAsync.asData?.value;
    final isEnRoutePickup =
        driverState.rescuePhase == ClaimRescuePhase.enRoutePickup;

    final destination = isEnRoutePickup
        ? batch?.pickupAddress ?? '—'
        : batch?.beneficiaryAddress ?? '—';
    final destinationName = isEnRoutePickup
        ? batch?.donorName ?? '—'
        : batch?.beneficiaryName ?? '—';
    final cta = isEnRoutePickup ? 'Arrived at Pick-up' : 'Arrived at Beneficiary';

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(batch?.lat ?? 13.7563, batch?.lng ?? 100.5018),
                    zoom: 14,
                  ),
                  markers: batch != null
                      ? {
                          Marker(
                            markerId: const MarkerId('dest'),
                            position: LatLng(batch.lat, batch.lng),
                          ),
                        }
                      : {},
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT DELIVERY',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Text(
                          'Status: ${isEnRoutePickup ? "En Route to Pickup" : "En Route to Beneficiary"}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESTINATION',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  destinationName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: Spacing.xs),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14),
                    const SizedBox(width: Spacing.xs),
                    Text(destination,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                if (batch?.totalPortions != null) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    '${batch!.totalPortions}x portions · ${batch.donorName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: Spacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _onArrived(context, isEnRoutePickup),
                    child: Text(cta),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onArrived(BuildContext context, bool isPickup) {
    if (isPickup) {
      context.push('/driver/pickup-verify');
    } else {
      context.push('/driver/verify-delivery');
    }
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```
flutter test test/widget/driver/claim_rescue_screen_test.dart
```

- [ ] **Step 5: Commit**

```
git add apps/mobile/lib/features/driver/presentation/screens/claim_rescue_screen.dart apps/mobile/test/widget/driver/claim_rescue_screen_test.dart
git commit -m "feat(driver): implement ClaimRescueScreen with two-phase en-route navigation"
```

---

## Task 12: PickupVerificationScreen

**Files:**
- Replace stub: `lib/features/driver/presentation/screens/pickup_verification_screen.dart`
- Create: `test/widget/driver/pickup_verification_screen_test.dart`

- [ ] **Step 1: Write widget test**

```dart
// test/widget/driver/pickup_verification_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/presentation/screens/pickup_verification_screen.dart';

Widget _wrap() => const ProviderScope(
      child: MaterialApp(home: PickupVerificationScreen()),
    );

void main() {
  testWidgets('shows Verify Pickup title and scan instructions', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Verify Pickup'), findsOneWidget);
    expect(find.text("Scan the QR code on the donor's device"), findsOneWidget);
    expect(find.text('Problems scanning? Enter code manually'), findsOneWidget);
  });

  testWidgets('tapping manual entry shows dialog', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Problems scanning? Enter code manually'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Enter Batch ID'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test — expect fail**

```
flutter test test/widget/driver/pickup_verification_screen_test.dart
```

- [ ] **Step 3: Implement PickupVerificationScreen**

```dart
// lib/features/driver/presentation/screens/pickup_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class PickupVerificationScreen extends ConsumerStatefulWidget {
  const PickupVerificationScreen({super.key});

  @override
  ConsumerState<PickupVerificationScreen> createState() =>
      _PickupVerificationScreenState();
}

class _PickupVerificationScreenState
    extends ConsumerState<PickupVerificationScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
  );
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    _validateAndNavigate(raw);
  }

  Future<void> _validateAndNavigate(String scannedBatchId) async {
    final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
    final batch = await ref
        .read(activeBatchForDriverProvider(uid).future);
    if (batch == null || batch.id != scannedBatchId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong QR code — try again.')),
        );
      }
      return;
    }
    _scanned = true;
    if (mounted) context.push('/driver/safety');
  }

  void _showManualEntry() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Batch ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Batch ID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _validateAndNavigate(controller.text.trim());
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Pickup')),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Text(
                    "Scan the QR code on the donor's device",
                    style: textTheme.bodyMedium
                        ?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: CustomPaint(
              size: const Size(220, 220),
              painter: _ReticlePainter(color: cs.primary),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(Spacing.md),
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextButton(
                  onPressed: _showManualEntry,
                  child: const Text('Problems scanning? Enter code manually'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  const _ReticlePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 40.0;
    final w = size.width;
    final h = size.height;
    canvas
      ..drawLine(const Offset(0, 40), Offset.zero, paint)
      ..drawLine(Offset.zero, const Offset(40, 0), paint)
      ..drawLine(Offset(w - len, 0), Offset(w, 0), paint)
      ..drawLine(Offset(w, 0), Offset(w, len), paint)
      ..drawLine(Offset(0, h - len), Offset(0, h), paint)
      ..drawLine(Offset(0, h), Offset(len, h), paint)
      ..drawLine(Offset(w - len, h), Offset(w, h), paint)
      ..drawLine(Offset(w, h), Offset(w, h - len), paint);
  }

  @override
  bool shouldRepaint(_ReticlePainter old) => old.color != color;
}
```

- [ ] **Step 4: Run tests — expect pass**

```
flutter test test/widget/driver/pickup_verification_screen_test.dart
```

- [ ] **Step 5: Commit**

```
git add apps/mobile/lib/features/driver/presentation/screens/pickup_verification_screen.dart apps/mobile/test/widget/driver/pickup_verification_screen_test.dart
git commit -m "feat(driver): implement PickupVerificationScreen with QR scan and manual fallback"
```

---

## Task 13: SafetyVerificationScreen

**Files:**
- Replace stub: `lib/features/driver/presentation/screens/safety_verification_screen.dart`
- Create: `test/widget/driver/safety_verification_screen_test.dart`

- [ ] **Step 1: Write widget test**

```dart
// test/widget/driver/safety_verification_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/presentation/screens/safety_verification_screen.dart';

Widget _wrap() => const ProviderScope(
      child: MaterialApp(home: SafetyVerificationScreen()),
    );

void main() {
  testWidgets('CTA is disabled when no checkboxes ticked', (tester) async {
    await tester.pumpWidget(_wrap());
    final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm & Complete Pickup'));
    expect(button.onPressed, isNull);
  });

  testWidgets('CTA stays disabled after ticking all boxes but no photo',
      (tester) async {
    await tester.pumpWidget(_wrap());
    // Tick all 3 checkboxes
    final checkboxes = find.byType(CheckboxListTile);
    expect(checkboxes, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      await tester.tap(checkboxes.at(i));
      await tester.pump();
    }
    final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm & Complete Pickup'));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows all 3 safety checklist items', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Food is stored in clean, food-grade containers'),
        findsOneWidget);
    expect(find.text('Temperature-sensitive items are in thermal bags'),
        findsOneWidget);
    expect(find.text('Vehicle storage area is clean and clear of contaminants'),
        findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test — expect fail**

```
flutter test test/widget/driver/safety_verification_screen_test.dart
```

- [ ] **Step 3: Implement SafetyVerificationScreen**

```dart
// lib/features/driver/presentation/screens/safety_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/shared/theme/spacing.dart';

const _checklistItems = [
  'Food is stored in clean, food-grade containers',
  'Temperature-sensitive items are in thermal bags',
  'Vehicle storage area is clean and clear of contaminants',
];

class SafetyVerificationScreen extends ConsumerStatefulWidget {
  const SafetyVerificationScreen({super.key});

  @override
  ConsumerState<SafetyVerificationScreen> createState() =>
      _SafetyVerificationScreenState();
}

class _SafetyVerificationScreenState
    extends ConsumerState<SafetyVerificationScreen> {
  final List<bool> _checked = List.filled(3, false);
  String? _photoPath;
  bool _loading = false;

  bool get _canConfirm =>
      _checked.every((v) => v) && _photoPath != null && !_loading;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) setState(() => _photoPath = file.path);
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
      final batch = await ref.read(activeBatchForDriverProvider(uid).future);
      if (batch == null) return;
      await ref
          .read(driverNotifierProvider.notifier)
          .confirmPickup(batch.id, _photoPath!);
      if (mounted) context.go('/driver/rescue');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Safety Verification')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: cs.primary),
              const SizedBox(width: Spacing.sm),
              Text('Pickup Checklist', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Please verify the following safety standards before confirming pickup.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: Spacing.sm),
          ...List.generate(
            _checklistItems.length,
            (i) => CheckboxListTile(
              title: Text(_checklistItems[i]),
              value: _checked[i],
              onChanged: (v) => setState(() => _checked[i] = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: cs.outlineVariant),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Icon(Icons.photo_camera, color: cs.primary),
              const SizedBox(width: Spacing.sm),
              Text('Photo Confirmation', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Upload a clear photo of the loaded food items to document the pickup.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: Spacing.sm),
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(
                  color: cs.primary,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _photoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(_photoPath!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: cs.primary, size: 32),
                        const SizedBox(height: Spacing.xs),
                        Text('Upload Pickup Photo',
                            style: textTheme.labelMedium
                                ?.copyWith(color: cs.primary)),
                        Text('Tap to select or take photo',
                            style: textTheme.bodySmall),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: FilledButton(
            onPressed: _canConfirm ? _confirm : null,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm & Complete Pickup'),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```
flutter test test/widget/driver/safety_verification_screen_test.dart
```

- [ ] **Step 5: Commit**

```
git add apps/mobile/lib/features/driver/presentation/screens/safety_verification_screen.dart apps/mobile/test/widget/driver/safety_verification_screen_test.dart
git commit -m "feat(driver): implement SafetyVerificationScreen with checklist + photo upload gate"
```

---

## Task 14: VerifyDeliveryScreen

**Files:**
- Replace stub: `lib/features/driver/presentation/screens/verify_delivery_screen.dart`
- Create: `test/widget/driver/verify_delivery_screen_test.dart`

- [ ] **Step 1: Write widget test**

```dart
// test/widget/driver/verify_delivery_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/presentation/screens/verify_delivery_screen.dart';

Widget _wrap() => const ProviderScope(
      child: MaterialApp(home: VerifyDeliveryScreen()),
    );

void main() {
  testWidgets('CTA disabled with nothing checked', (tester) async {
    await tester.pumpWidget(_wrap());
    final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm Delivery Completion'));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows both handover verification items', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Food batch handed over securely to shelter staff'),
        findsOneWidget);
    expect(find.text('Shelter staff confirmed item quantities match'),
        findsOneWidget);
  });

  testWidgets('CTA enabled after both checkboxes selected', (tester) async {
    await tester.pumpWidget(_wrap());
    final checks = find.byType(CheckboxListTile);
    await tester.tap(checks.at(0));
    await tester.pump();
    await tester.tap(checks.at(1));
    await tester.pump();
    final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm Delivery Completion'));
    expect(button.onPressed, isNotNull);
  });
}
```

- [ ] **Step 2: Run test — expect fail**

```
flutter test test/widget/driver/verify_delivery_screen_test.dart
```

- [ ] **Step 3: Implement VerifyDeliveryScreen**

```dart
// lib/features/driver/presentation/screens/verify_delivery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/shared/theme/spacing.dart';

const _handoverItems = [
  'Food batch handed over securely to shelter staff',
  'Shelter staff confirmed item quantities match',
];

class VerifyDeliveryScreen extends ConsumerStatefulWidget {
  const VerifyDeliveryScreen({super.key});

  @override
  ConsumerState<VerifyDeliveryScreen> createState() =>
      _VerifyDeliveryScreenState();
}

class _VerifyDeliveryScreenState extends ConsumerState<VerifyDeliveryScreen> {
  final List<bool> _checked = List.filled(2, false);
  final TextEditingController _notesController = TextEditingController();
  bool _loading = false;

  bool get _canConfirm => _checked.every((v) => v) && !_loading;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
      final batch = await ref.read(activeBatchForDriverProvider(uid).future);
      if (batch == null) return;
      final notes = _notesController.text.trim();
      await ref
          .read(driverNotifierProvider.notifier)
          .confirmDelivery(batch.id, notes.isEmpty ? null : notes);
      if (mounted) context.push('/driver/completed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Delivery')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: cs.primary),
              const SizedBox(width: Spacing.sm),
              Text('Handover Verification', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          ...List.generate(
            _handoverItems.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: CheckboxListTile(
                title: Text(_handoverItems[i]),
                value: _checked[i],
                onChanged: (v) => setState(() => _checked[i] = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'NOTES OR FEEDBACK (OPTIONAL)',
            style: textTheme.labelSmall,
          ),
          const SizedBox(height: Spacing.xs),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'E.g., Storage location, specific staff member name...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: FilledButton(
            onPressed: _canConfirm ? _confirm : null,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm Delivery Completion'),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```
flutter test test/widget/driver/verify_delivery_screen_test.dart
```

- [ ] **Step 5: Commit**

```
git add apps/mobile/lib/features/driver/presentation/screens/verify_delivery_screen.dart apps/mobile/test/widget/driver/verify_delivery_screen_test.dart
git commit -m "feat(driver): implement VerifyDeliveryScreen with handover checklist and optional notes"
```

---

## Task 15: DeliveryCompletedScreen

**Files:**
- Replace stub: `lib/features/driver/presentation/screens/delivery_completed_screen.dart`
- Create: `test/widget/driver/delivery_completed_screen_test.dart`

- [ ] **Step 1: Write widget test**

```dart
// test/widget/driver/delivery_completed_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/features/driver/presentation/screens/delivery_completed_screen.dart';

const _fakeBatch = BatchSummary(
  id: 'b1',
  donorName: 'Central Bakery',
  pickupAddress: '123 Baker St',
  beneficiaryAddress: '1200 Greenway Blvd',
  beneficiaryName: 'Haven Shelter',
  totalPortions: 38,
  lat: 13.7,
  lng: 100.5,
  foodCategory: 'local_pizza',
);

class _FakeNotifier extends DriverNotifier {
  @override
  DriverState build() => const DriverState(step: DriverStep.delivered);
  @override
  void resetToIdle() {}
}

Widget _wrap() => ProviderScope(
      overrides: [
        driverNotifierProvider.overrideWith(() => _FakeNotifier()),
        activeBatchForDriverProvider('').overrideWith(
            (_) => Stream.value(_fakeBatch)),
      ],
      child: const MaterialApp(home: DeliveryCompletedScreen()),
    );

void main() {
  testWidgets('shows Delivery Completed heading', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    expect(find.text('Delivery Completed!'), findsOneWidget);
  });

  testWidgets('shows beneficiary name and portions', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    expect(find.textContaining('Haven Shelter'), findsOneWidget);
    expect(find.textContaining('38'), findsOneWidget);
  });

  testWidgets('Done and Back to Dashboard buttons present', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Back to Dashboard'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test — expect fail**

```
flutter test test/widget/driver/delivery_completed_screen_test.dart
```

- [ ] **Step 3: Implement DeliveryCompletedScreen**

```dart
// lib/features/driver/presentation/screens/delivery_completed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/services/service_providers.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class DeliveryCompletedScreen extends ConsumerWidget {
  const DeliveryCompletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final batchAsync = ref.watch(activeBatchForDriverProvider(uid));
    final pointsAsync = ref.watch(_pointsProvider(uid));

    final batch = batchAsync.asData?.value;
    final points = pointsAsync.asData?.value ?? 0;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void onDone() {
      ref.read(driverNotifierProvider.notifier).resetToIdle();
      context.go('/driver');
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: cs.primary, size: 48),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'Delivery Completed!',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),
              if (batch != null)
                Text(
                  "Thank you! You've successfully rescued and delivered "
                  "${batch.totalPortions} portions of food to ${batch.beneficiaryName}.",
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: Spacing.xl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Impact Earned', style: textTheme.titleSmall),
                          const Icon(Icons.eco, color: Colors.green),
                        ],
                      ),
                      const SizedBox(height: Spacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _ImpactTile(
                              value: batch != null
                                  ? '${(batch.totalPortions * 0.4).toStringAsFixed(0)} kg'
                                  : '—',
                              label: 'CO2 SAVED',
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: _ImpactTile(
                              value: '${batch?.totalPortions ?? 0}',
                              label: 'MEALS PROVIDED',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      '+$points Points Earned',
                      style: textTheme.labelMedium?.copyWith(
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  child: const Text('Done'),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onDone,
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Watch points delta: snapshot before and after delivery complete.
// Cloud Function writes updated points asynchronously; we watch the live value.
@riverpod
Stream<int> _points(Ref ref, String uid) =>
    ref.watch(firestoreServiceProvider).watchUserPoints(uid);

class _ImpactTile extends StatelessWidget {
  const _ImpactTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style:
                  textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(label,
              style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run codegen (for `@riverpod _points`)**

```
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Run tests — expect pass**

```
flutter test test/widget/driver/delivery_completed_screen_test.dart
```

- [ ] **Step 6: Commit**

```
git add apps/mobile/lib/features/driver/presentation/screens/delivery_completed_screen.dart apps/mobile/test/widget/driver/delivery_completed_screen_test.dart
git commit -m "feat(driver): implement DeliveryCompletedScreen with impact stats and points earned"
```

---

## Task 16: Implement BatchQrScreen (donor-side)

**Files:**
- Implement: `lib/features/donor/presentation/screens/batch_qr_screen.dart`
- Create: `test/widget/driver/batch_qr_screen_test.dart`

- [ ] **Step 1: Write widget test**

```dart
// test/widget/driver/batch_qr_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saveameal/features/donor/presentation/screens/batch_qr_screen.dart';

Widget _wrap(String batchId) => ProviderScope(
      child: MaterialApp(
        home: BatchQrScreen(batchId: batchId),
      ),
    );

void main() {
  testWidgets('renders a QrImageView widget with the batchId', (tester) async {
    await tester.pumpWidget(_wrap('batch-abc'));
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('shows Batch QR Code title', (tester) async {
    await tester.pumpWidget(_wrap('batch-abc'));
    expect(find.text('Batch QR Code'), findsOneWidget);
  });

  testWidgets('shows the batch ID as subtitle', (tester) async {
    await tester.pumpWidget(_wrap('batch-abc'));
    expect(find.textContaining('batch-abc'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test — expect fail**

```
flutter test test/widget/driver/batch_qr_screen_test.dart
```

- [ ] **Step 3: Implement BatchQrScreen**

```dart
// lib/features/donor/presentation/screens/batch_qr_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class BatchQrScreen extends StatelessWidget {
  const BatchQrScreen({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Batch QR Code')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Show this QR code to the driver at pickup',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xl),
              Container(
                padding: const EdgeInsets.all(Spacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: batchId,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                batchId,
                style: textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```
flutter test test/widget/driver/batch_qr_screen_test.dart
```

- [ ] **Step 5: Commit**

```
git add apps/mobile/lib/features/donor/presentation/screens/batch_qr_screen.dart apps/mobile/test/widget/driver/batch_qr_screen_test.dart
git commit -m "feat(donor): implement BatchQrScreen with qr_flutter QR code display"
```

---

## Task 17: Final verification

- [ ] **Step 1: Run all tests**

```
flutter test
```

Expected: all tests pass, zero failures.

- [ ] **Step 2: Run static analysis**

```
flutter analyze
dart format . --set-exit-if-changed
```

Expected: no warnings or errors, no formatting issues.

- [ ] **Step 3: Run build_runner one final time**

```
dart run build_runner build --delete-conflicting-outputs
```

Expected: no errors, all generated files up to date.

- [ ] **Step 4: Final commit**

```
git add -A
git commit -m "chore(driver): final codegen sync and formatting pass"
```

---

## Self-Review Checklist

**Spec coverage:**

| Spec requirement | Task |
|---|---|
| Driver sees open batches as food-category markers | Task 9 |
| Marker tap shows preview card with "View Job →" | Task 9 |
| Claiming uses Firestore transaction; concurrent claim shows snackbar | Task 3, 10 |
| Live location writes to driverLocations every 30 s | Task 3, 7 |
| Pickup requires QR scan + safety checklist + photo | Tasks 12, 13 |
| Delivery requires handover checkboxes + optional notes | Task 14 |
| Completion screen shows impact stats and points earned | Task 15 |
| Batch status: open → claimed → picked_up → delivered | Tasks 3, 5, 6 |
| PickupScreen and DeliveryScreen stubs removed | Task 8 |
| BatchQrScreen implemented | Task 16 |
| Every new screen has a widget test | Tasks 9–16 |
| Foreground-only location permission | Task 7 |
| Points = max(10, totalPortions) via Cloud Function; app reads live | Task 15 |
