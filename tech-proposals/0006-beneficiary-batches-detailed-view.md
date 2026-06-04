---
title: "0006: Beneficiary Batch Detailed View"
description: "Fill the stub DeliveryDetailScreen with item-level batch content, driver/ETA info, and live status — resolving the core architectural gap where IntakeRequest carries no item list."
---

# PROP-0006: Beneficiary Batch Detailed View

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-04
**Spec:** (pending approval)
**Approved by:** ALORA

---

## Problem

`DeliveryDetailScreen` at `/beneficiary/delivery/:batchId` is navigable from the dashboard's "View Details" tap on every `ActiveDeliveryCard`, but the screen renders nothing beyond a raw `batchId` string. This means a beneficiary who taps through to see what food is coming, who is bringing it, and when — receives no information.

The root architectural gap is that the `IntakeRequest` domain entity carries only an aggregated `mealDescription` string and a total `weightKg` float. The item array from `BatchModel.items` (each item carrying `name`, `category`, `weightKg`, and `expiryTime`) is silently dropped inside `IntakeRequestModel.fromBatch()` when mapping to domain. There is no field on `IntakeRequest` to hold item-level data.

A secondary gap is that `WatchIncomingBatchUsecase` — the intended use case for this screen — exists only as a stub with a `TODO` and no `call` method.

The `intakeRequestProvider(batchId)` stream provider is already wired in `beneficiary_provider.dart` and the route is already registered, so the data plumbing from Firestore to the provider exists. Only the domain entity shape and the screen implementation are missing.

The solution must satisfy four requirements simultaneously:

1. **Offline / cached** — the last known state must render without a live connection (Firestore offline persistence or Hive).
2. **Real-time** — status transitions (e.g. `claimed` → `pickedUp`) must arrive live without a manual refresh.
3. **Item-level detail** — individual food items (name, category, weightKg) must be individually listed, not collapsed into a summary string.
4. **Driver contact / ETA** — `volunteerName` and `estimatedArrivalMinutes` must be surfaced if present.

---

## Proposed Solution

**Recommendation: Option B — new `IntakeRequestDetail` entity.**

Introduce a new pure-Dart domain entity `IntakeRequestDetail` that carries all fields of `IntakeRequest` plus `List<IntakeItem> items`, where `IntakeItem` is a new pure-Dart value type (`name`, `category`, `weightKg`). Add a corresponding `watchIntakeRequestDetail(batchId)` method to `IntakeRepository` and implement it in `FirestoreIntakeRepository` by mapping `batch.items` into `List<IntakeItem>`. Wire a new `@riverpod` family provider `intakeRequestDetailProvider(batchId)` that calls a new `WatchIntakeRequestDetailUseCase`. Implement `DeliveryDetailScreen` as a `ConsumerStatefulWidget` that watches this provider.

Full justification and trade-off reasoning is in the Options section below.

---

## Alternatives Considered

### A — Enrich `IntakeRequest` with `List<IntakeItem> items`

Add a `List<IntakeItem> items` field to the existing `IntakeRequest` entity and update `IntakeRequestModel.fromBatch()` to populate it. Implement the existing `WatchIncomingBatchUsecase` stub (which already references `BeneficiaryRepository`) to serve the detail screen. Wire `DeliveryDetailScreen` against the existing `intakeRequestProvider(batchId)`.

**Upside:** single entity, minimal new files, the existing `intakeRequestProvider` family provider is already in `beneficiary_provider.dart` and can be used directly, `WatchIncomingBatchUsecase` stub can be completed without a new use case file.

**Downside:** `watchActiveDeliveries(beneficiaryId)` returns `Stream<List<IntakeRequest>>` and is called by the dashboard list. Every beneficiary dashboard rebuild now carries the full item array for every active delivery, even though the list card only reads `volunteerName`, `portions`, `mealDescription`, `status`, and `estimatedArrivalMinutes`. On a batch with ten items, each Firestore snapshot emitted to the list stream will deserialise and allocate a `List<BatchItemModel>` per batch and then immediately discard it in `ActiveDeliveryCard`. This is unnecessary memory pressure that scales with batch count and snapshot frequency. Additionally, widening `IntakeRequest` couples the list concern and the detail concern into one type; a future change to either (e.g. adding `expiryTime` to items for the detail, or removing `portions` from the list) requires touching a shared entity.

**Rejected in favour of Option B** for the overhead and coupling reasons stated above. The item list is exclusively a detail-view concern.

---

### B — New `IntakeRequestDetail` entity for the detail view (Recommended)

Create a new pure-Dart entity `IntakeRequestDetail` with all fields from `IntakeRequest` plus `List<IntakeItem> items`. `IntakeItem` is a new pure-Dart value class: `String name`, `String category`, `double weightKg`. Add `watchIntakeRequestDetail(String batchId)` to the `IntakeRepository` interface. Implement it in `FirestoreIntakeRepository` by reusing the existing `_datasource.watchBatch(batchId)` call and mapping `batch.items` to `List<IntakeItem>`. Introduce `WatchIntakeRequestDetailUseCase` and a `intakeRequestDetailProvider(batchId)` Riverpod family provider. `DeliveryDetailScreen` watches this provider.

**Upside:** zero impact on the existing `watchActiveDeliveries` code path — `IntakeRequest` and its mapper are untouched; the dashboard list stream continues to deserialise only the fields it displays. Domain intent is explicit: the detail entity self-documents that it carries items. Each entity carries only what its consumer needs, consistent with ADR-0008 (domain entities are plain Dart, shaped per consumer).

**Downside:** field duplication between `IntakeRequest` and `IntakeRequestDetail` (all scalar fields appear in both). One additional file per layer: one domain entity (`intake_request_detail.dart`), one domain use case (`watch_intake_request_detail_usecase.dart`), one mapper extension on `IntakeRequestModel`, one provider. If a scalar field (e.g. `volunteerName`) needs to change its type, it must be changed in two domain entities and two mapper extension methods.

**Not rejected — this is the recommendation.**

---

### C — Fetch `BatchModel` directly in the presentation layer

Skip domain mapping for the detail screen entirely. The Riverpod provider calls `FirestoreService.watchBatch(batchId)` directly and passes the `BatchModel` to the screen, which reads `batch.items` natively.

**Upside:** no new entity, no mapper, quickest to implement.

**Downside:** Presentation depends directly on a Data-layer model (`BatchModel` is `@freezed` with `json_serializable`, lives in `core/models/`). This violates the Clean Architecture constraint that the Presentation layer depends on Domain only — never on Data directly. It also couples the screen to the Firestore field schema; renaming `batch.items` in Firestore requires a change in the widget. Rejected outright as an architecture violation.

---

## Open Questions

1. **Driver contact action.** `BatchModel` has `driverId` and `volunteerName` but no phone number field. If "contact driver" is in scope for this screen — even as a "call" deep-link — the Firestore schema needs a `volunteerPhone` field and corresponding domain exposure. Is this in scope for the first iteration, or deferred?

2. **Firestore offline persistence.** The offline/cached requirement assumes that Firestore's local disk cache retains the last-seen batch document. Is `settings: const Settings(persistenceEnabled: true)` already set in the app's Firebase initialisation? If not, this proposal must either enable it (a one-line change with platform implications for iOS) or substitute Hive as an explicit cache layer for this screen.

3. **Item photo display.** `BatchItemModel.photoUrl` is a nullable field. Should `IntakeItem` expose `photoUrl` and should the detail screen render item thumbnails via `CachedNetworkImage`? If photos are optional and sparsely populated, a fallback icon strategy must be defined. If they are reliably absent in current seed data, photo rendering should be deferred.

4. **Cancelled-batch screen reachability.** A beneficiary can navigate to `/beneficiary/delivery/:batchId` from the dashboard only while the delivery is active. However, if the screen is reached from a deep link or notification and the batch status is `cancelled`, should the screen render a cancellation summary (status, `cancellationReason`) or should the router guard redirect away? This affects whether `IntakeRequestDetail` needs to be reachable for `cancelled` batches and whether a router redirect rule is part of this spec.

---

## Acceptance Criteria

**Domain layer**

- A new pure-Dart file `apps/mobile/lib/features/beneficiary/domain/entities/intake_request_detail.dart` defines `IntakeRequestDetail` with fields: `batchId`, `beneficiaryId`, `donorId`, `status` (`IntakeStatus`), `portions`, `mealDescription`, `weightKg`, `volunteerId?`, `volunteerName?`, `estimatedArrivalMinutes?`, `cancellationReason?`, `createdAt?`, `updatedAt?`, and `items` (`List<IntakeItem>`).
- A new pure-Dart file defines `IntakeItem` with fields: `name` (`String`), `category` (`String`), `weightKg` (`double`). `IntakeItem` has zero Flutter or backend imports.
- `IntakeRequestDetail` has zero Flutter or backend imports.
- `IntakeRepository` (domain interface) declares `Stream<IntakeRequestDetail?> watchIntakeRequestDetail(String batchId)`.
- A new use case `WatchIntakeRequestDetailUseCase` in the domain layer has a `call(String batchId)` method returning `Stream<IntakeRequestDetail?>` by delegating to the repository.

**Data layer**

- `FirestoreIntakeRepository` implements `watchIntakeRequestDetail(batchId)` by calling `_datasource.watchBatch(batchId)` and mapping each emitted `BatchModel?` to `IntakeRequestDetail?` via an extension method on `IntakeRequestModel` (or a standalone mapper).
- The mapping populates `items` from `batch.items`, converting each `BatchItemModel` into an `IntakeItem`.
- The existing `watchIntakeRequest(batchId)` implementation and its mapping are untouched — `IntakeRequest` gains no new fields.
- No Firestore types (`DocumentSnapshot`, `QuerySnapshot`, etc.) appear outside the datasource or `FirestoreService`.

**Presentation layer**

- A `@riverpod` family provider `intakeRequestDetailProvider(Ref ref, String batchId)` returns `Stream<IntakeRequestDetail?>` by calling `WatchIntakeRequestDetailUseCase`.
- `DeliveryDetailScreen` is rewritten as a `ConsumerStatefulWidget` that watches `intakeRequestDetailProvider(batchId)`.
- The screen renders a step indicator with three labelled steps corresponding to `IntakeStatus` values: `pending` = Submitted, `dispatched` = In Transit, `collected` = Delivered. The active step is highlighted.
- The screen renders `volunteerName` and `estimatedArrivalMinutes` in a driver info row when both fields are non-null.
- The screen renders a `ListView.builder` (never unbounded `ListView`) of `IntakeItem` entries, each row showing item name, category, and weightKg.
- When status is `cancelled`, the screen renders a cancellation banner displaying `cancellationReason` if present.
- While the stream is loading, a `CircularProgressIndicator` is shown.
- When the stream emits `null` (batch not found), an error state widget is shown.
- All text styles use `Theme.of(context).textTheme.*` — no hardcoded font sizes.
- All colours use `cs.*` or `ac.*` — no hardcoded colour values.
- No spacing magic numbers — all spacing from the project spacing scale.
- All remote images (item photos if rendered) go through `CachedNetworkImage`.

**Tests**

- A widget test for `DeliveryDetailScreen` covers: loading state, `dispatched` state with items and volunteer info, `cancelled` state with a cancellation reason, and `null` stream (not-found state).
- A unit test for `WatchIntakeRequestDetailUseCase` verifies it delegates to the repository and returns the stream unmodified.
- A unit test for the `IntakeRequestModel` → `IntakeRequestDetail` mapper verifies that `items` is populated correctly from `batch.items` and that an empty items list maps to an empty `List<IntakeItem>`.

**Architecture constraints**

- `DeliveryDetailScreen` imports from `domain/` and `presentation/` only — no import of `BatchModel`, `BatchItemModel`, `FirestoreIntakeRepository`, or any `data/` type.
- `WatchIntakeRequestDetailUseCase` imports only from `domain/` — no Flutter, Riverpod, or Firestore imports.
- `flutter analyze` reports zero new warnings after implementation.
- `dart format .` is run before the PR is submitted.
