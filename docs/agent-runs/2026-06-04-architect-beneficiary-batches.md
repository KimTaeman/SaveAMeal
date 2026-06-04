# Architect Review — feat/beneficiary-batches
Date: 2026-06-04
Reviewer: architect

---

## Findings

### [WARNING] `recentDeliveries` provider calls `IntakeRepository` directly, bypassing the use-case layer

`intakeRequestDetail` is correctly wired through `WatchIntakeRequestDetailUseCase`. `recentDeliveries` calls `ref.watch(intakeRepositoryProvider).watchRecentDeliveries(beneficiaryId)` without a corresponding use-case class. A third provider — the pre-existing `driverLocation` — goes further still, calling `firestoreServiceProvider.watchDriverLocation` directly, crossing two layer boundaries.

The risk is consistency, not a functional defect: the codebase now has three different patterns in one provider file (service bypass, repository bypass, use-case). Future engineers adding providers have no clear signal for when a use-case is required.

**Fix (required before next feature):** For `recentDeliveries`, either create a `WatchRecentDeliveriesUseCase` that wraps the one-liner (matching the pattern for `intakeRequestDetail`) or document via ADR the policy that passthrough read-only streams are exempt. ADR-0013 has been written capturing the current decision as Option 2 (repository bypass accepted; `driverLocation` service bypass flagged). For `driverLocation`, a follow-on spec should wrap the `FirestoreService` call behind a cross-feature repository.

This is classified WARNING, not BLOCKING, because the architecture boundary that matters most — no Firebase import in Domain, no Data import in Presentation — is intact. The repository is still the domain boundary entry point, and the provider is testable via Riverpod overrides (evidenced by the delivery-detail screen tests).

Note: the pre-existing `intakeRequest` provider also calls the repository directly (line 58 of `beneficiary_provider.dart`). That pre-dates this PR and is not introduced here, but the same policy applies.

---

### [WARNING] `beneficiaryId: batch.beneficiaryId ?? ''` in `batchModelToDetailDomain` — empty string fallback is silent

`BatchModel.beneficiaryId` is nullable. The mapper coerces null to `''`. `IntakeRequestDetail.beneficiaryId` is typed as a non-null `String`. The downstream consumer, `RecentDeliveriesSection`, calls `recentDeliveriesProvider(detail.beneficiaryId)`, which issues a Firestore query `where('beneficiaryId', isEqualTo: '')`. This query returns an empty result set rather than an error, so the section renders `SizedBox.shrink()` — silently showing nothing rather than revealing the data problem.

The same coercion pattern already exists in `IntakeRequestModel.fromBatch` (line 79), so this PR is consistent with the existing convention. However, the convention itself carries risk.

**Fix (recommended, not blocking):** Make `IntakeRequestDetail.beneficiaryId` nullable (`String?`) to let the type system propagate the absence. If that is too wide a change for this PR, add an assert in the mapper (`assert(batch.beneficiaryId != null, ...)`) so debug builds surface the problem, and file a follow-on issue to make the field nullable. The empty-string fallback must never silently drive a live Firestore query.

---

### [WARNING] `estimatedArrivalMinutes` and `cancellationReason` are hardcoded null — `DriverInfoCard` ETA column and `_CancellationBanner` are both wired to these fields

`batchModelToDetailDomain` sets both to `null` because `BatchModel` has no corresponding fields. The UI for ETA (`DriverInfoCard` lines 136–154) and the cancellation reason text (`_CancellationBanner` line 169) each guard on null and render gracefully — `ETA unknown` and no reason text respectively.

This is an accepted placeholder (documented in the session log and ADR-0012) and the UI handles the null case correctly. However, the ticket is now open-ended: there is no corresponding `BatchModel` field to map to, no Firestore schema entry, and no spec task tracking the completion.

**Fix (INFO, for tracking):** Create a follow-on issue or spec task for: (1) adding `estimatedArrivalMinutes` as a server-computed field to `BatchModel`, (2) amending `batchModelToDetailDomain`, (3) amending `DriverInfoCard` to consume the real value. Until that task ships, the mapper comment `// not yet on BatchModel` must stay in place.

---

### [INFO] `portions` is computed as `items.length`, not as a stored field — inconsistency with `IntakeRequestModel`

`batchModelToDetailDomain` sets `portions: items.length`. `IntakeRequestModel.fromBatch` does the same. This is consistent, but `portions` in `IntakeRequestDetail` is semantically "number of item line-items in the batch", not "number of individual meals". `BatchItemsCard` renders `'${detail.portions} Portions'` — which may be confusing if a single line item represents multiple identical portions.

**Fix (INFO):** No action required for this PR. If `BatchModel` ever gains a `portions` integer field (separate from `items.length`), both mappers will need updating. Track this when the batch creation form is revisited.

---

### [INFO] `_formatRelativeDate` is a package-private top-level function in `recent_deliveries_section.dart`

The function formats a `DateTime` into a relative label (Today, Yesterday, N days ago, dd/mm/yyyy). It lives in the presentation layer inside a widget file, making it inaccessible to any other widget or screen without duplication. All 13 date-formatting widget tests exercise it indirectly — it cannot be unit tested in isolation.

**Fix (INFO, not blocking):** Move to a `shared/formatters/date_formatters.dart` file as a named export. This makes it unit-testable directly and available to any future screen that needs the same relative-date display. ADR-0009 notes that a `formatters/` layer should be adopted when more than three screens perform non-trivial enum or value formatting.

---

### [INFO] `DriverInfoCard` imports `core/models/driver_location_model.dart` — data-layer model in a presentation widget

`driver_info_card.dart` line 4 imports `package:saveameal/core/models/driver_location_model.dart`. `DriverLocationModel` is a Freezed Firestore model sitting in `core/models/` — the data layer. The widget uses it only to read `.lat` and `.lng` to pass to `LatLng`. This is the same existing pattern used by the tracking screen elsewhere in the project.

Strictly speaking, the widget should receive a pure-domain location type (e.g., `DriverLocation` entity with `lat` and `lng`). In practice the pre-existing `driverLocationProvider` already exposes `DriverLocationModel?` as its stream type, so the widget cannot avoid the import without adding a mapping step.

**Fix (INFO, not blocking):** This pre-dates the PR. Record as a known violation to address when a domain `DriverLocation` entity is introduced. No action required to merge this PR.

---

### [APPROVED — layer boundaries confirmed clean]

**Domain entities:** `IntakeItem`, `IntakeRequestDetail`, and `RecentDelivery` are all pure Dart with zero Flutter or Firebase imports. `IntakeRequestDetail` imports only `intake_item.dart` and `intake_request.dart` — both domain entities. `IntakeRepository` imports only domain types. `WatchIntakeRequestDetailUseCase` imports only domain types and the repository interface.

**Mapper placement:** `batchModelToDetailDomain` and `mapIntakeStatus` living as top-level functions in `intake_request_model.dart` (data layer) is correct. The data layer owns the translation from Firestore/model types to domain entities. No domain entity imports a data-layer type.

**Data layer:** `FirestoreIntakeRepository` imports datasource, model, and domain entities — all appropriate. The `RecentDelivery` mapping in the repository is an inline lambda, which is acceptable given the trivial field count.

**Presentation layer:** `DeliveryDetailScreen`, `BatchItemsCard`, `RecentDeliveriesSection` import domain entities and Riverpod providers — no data-layer imports. The `DriverInfoCard` data-layer import is a pre-existing pattern flagged as INFO above.

**Tests:** Use-case test uses a handwritten `_FakeIntakeRepository` — no Mockito dependency, no build_runner requirement. Mapper tests cover all six `BatchStatus` → `IntakeStatus` paths. Widget tests stub both `intakeRequestDetailProvider` and `recentDeliveriesProvider` via Riverpod overrides. `DeliveryDetailScreen` widget test correctly stubs `driverLocationProvider` to return null (bypassing GoogleMap platform channel).

---

## Verdict

APPROVED — with two warnings that must be addressed before the next PR adds new providers or re-uses the `recentDeliveries` pattern.

**Blocking findings:** none.

**Non-blocking actions required:**
1. (WARNING) Decide on and document the use-case bypass policy for passthrough stream providers, or add `WatchRecentDeliveriesUseCase`. ADR-0013 captures the current decision; the team must ratify it.
2. (WARNING) File a follow-on issue for `beneficiaryId ?? ''` — either make the field nullable in the entity or add a debug assert in the mapper.
3. (INFO) File a follow-on task for `estimatedArrivalMinutes` / `cancellationReason` — these fields must not remain as permanent nulls without a tracked path to completion.
