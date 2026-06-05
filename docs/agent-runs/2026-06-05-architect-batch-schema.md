# Architect Review — feature/batch-schema-consistency
Date: 2026-06-05
Reviewer: architect

## Verdict: CHANGES REQUESTED

Two blocking issues must be resolved before merge. Three non-blocking issues are
flagged for follow-up in separate tickets.

---

## Findings

### [BLOCKING] Domain entity imports a presentation-layer formatting utility

- **File:** `apps/mobile/lib/features/beneficiary/domain/entities/order_history_entry.dart` line 3, line 20
- **Rule:** Domain layer — zero Flutter or backend imports. Domain must not depend on presentation concerns.
- **Detail:** `order_history_entry.dart` imports `package:saveameal/shared/utils/batch_id_formatter.dart` and exposes `String get displayId => formatBatchId(id)`. `formatBatchId` is a display-formatting function — it produces a short, hash-prefixed ID string whose sole purpose is human-readable UI output. Display formatting is a presentation concern. The fact that `batch_id_formatter.dart` happens to be pure Dart does not make it a domain concern. The CLAUDE.md constraint reads "Domain layer: zero Flutter or backend imports", but the intent is broader: domain entities must not embed presentation logic. Mixing display formatting into an entity couples every consumer of `OrderHistoryEntry` (including future non-UI consumers such as notification services, export pipelines, or server-side Dart) to a UI formatting decision.
- **Recommendation:** Remove `displayId` from `OrderHistoryEntry`. Move the call site to the presentation layer — either in `OrderHistoryCard` (widget) or in a Riverpod provider that maps the entity to a view-model. `batch_id_formatter.dart` stays in `shared/utils/` and is called from presentation only.

---

### [BLOCKING] `BatchStatus` canonical home is a cross-feature concern buried in a single feature's domain

- **File:** `apps/mobile/lib/features/donor/domain/entities/batch.dart` line 3; `apps/mobile/lib/services/firestore_service.dart` line 7; `apps/mobile/lib/core/models/batch_model.dart` line 3
- **Rule:** Clean Architecture — feature boundaries must not create hidden coupling between unrelated layers.
- **Detail:** `BatchStatus` is consumed today by `firestore_service.dart` (services layer), `batch_model.dart` (core/data layer), and all donor presentation screens. The grep shows it is not yet imported by driver or beneficiary domain — but `BatchStatus` is a lifecycle enum that semantically belongs to the batch aggregate, which spans all three roles. Placing it inside `features/donor/domain/` makes `donor` the implicit owner of a shared contract. Any future driver or beneficiary domain entity that needs to branch on status would be forced to import from a sibling feature's domain, creating cross-feature domain coupling — the pattern that ADR-0012 was written to prevent. The services layer (`firestore_service.dart`) importing directly from `features/donor/domain/` is an immediate violation of that boundary: services are supposed to be feature-agnostic.
- **Recommendation:** Move `BatchStatus` to `lib/shared/domain/entities/batch_status.dart`, mirroring the precedent set by `FoodCategory` in `lib/shared/domain/entities/food_category.dart`. Update all three current import sites. This is a small mechanical change that eliminates a structural debt before it spreads.

---

### [HIGH] `pickupWindowStart` / `pickupWindowEnd` typed as `String?` in domain entity

- **File:** `apps/mobile/lib/features/donor/domain/entities/batch.dart` lines 51–52
- **Rule:** Domain entities model business concepts using the strongest available type.
- **Detail:** A pickup window is a time-based concept. Storing it as `String?` in the domain entity leaks the serialisation format (ISO-8601 string, Firestore Timestamp string, or free text) into the domain layer. If the format ever changes, every domain consumer must be updated. The `BatchModel` (data layer) correctly owns serialisation concerns and may reasonably store these as `String?` for JSON round-tripping, but the domain entity should represent the concept as `DateTime?`. The mapper in `BatchModel` → `Batch` is the correct place to parse the string.
- **Recommendation:** Change `pickupWindowStart` and `pickupWindowEnd` to `DateTime?` in `Batch`. Update `BatchModel`-to-`Batch` mapper to parse the string. This is not introduced by this PR but is surfaced by the 12-field expansion — track as a follow-up ticket if not fixing now. This finding does not block merge on its own but pairs with the blocking items to define the overall schema health.

---

### [MEDIUM] `shared/utils/` directory has no prior convention in the project

- **File:** `apps/mobile/lib/shared/utils/batch_id_formatter.dart`
- **Rule:** CLAUDE.md folder conventions — `shared/` contains `widgets/` and `theme/`. No `utils/` precedent exists.
- **Detail:** The project's folder structure defines `shared/widgets/` and `shared/theme/`. This PR adds `shared/utils/` for a single free-standing function. A `utils/` catch-all tends to accumulate unrelated helpers over time. The project already has `shared/domain/entities/` (established for `FoodCategory`) as a home for shared pure-Dart constructs. The formatter is not a domain entity, so `shared/domain/` is not the right fit either.
- **Recommendation:** Accept `shared/utils/` as a new established directory for pure-Dart, presentation-adjacent helpers (formatters, validators, extension helpers). Document the intent in a brief comment at the top of the directory's first file, or in `CLAUDE.md`. The current file content is correct; the concern is that the directory needs a declared scope to stay tidy. Raise a follow-up to add this to CLAUDE.md conventions. Does not block merge once the two blocking issues above are resolved.

---

### [INFO] `batch_model.dart` importing from `features/donor/domain/` is correct but temporary

- **File:** `apps/mobile/lib/core/models/batch_model.dart` line 3
- **Rule:** Data layer may depend on domain layer (correct direction).
- **Detail:** The import direction (data → domain) is architecturally valid. However, once `BatchStatus` is moved to `shared/domain/` (see BLOCKING finding above), this import site changes from `features/donor/domain/entities/batch.dart` to `shared/domain/entities/batch_status.dart`. No action required beyond tracking with the BLOCKING item.

---

### [INFO] `FoodCategory.fromString` static factory on domain enum — correct placement

- **File:** `apps/mobile/lib/shared/domain/entities/food_category.dart`
- **Rule:** Domain entities are pure Dart.
- **Detail:** The static factory is pure Dart with no external imports. Parsing from a raw string (e.g., Firestore value) at the domain boundary is an acceptable pattern when no Freezed/JSON machinery is available for enums. No action required.

---

## Summary

Two blocking issues must be resolved before this branch can merge:

1. Remove `displayId` (and the `batch_id_formatter.dart` import) from `OrderHistoryEntry`. Move the formatting call to the presentation layer.
2. Move `BatchStatus` out of `features/donor/domain/` into `shared/domain/entities/batch_status.dart`, matching the `FoodCategory` precedent. Update `firestore_service.dart`, `batch_model.dart`, and all presentation-layer import sites.

The `pickupWindowStart`/`pickupWindowEnd` typing issue (HIGH) should be tracked as a follow-up ticket unless the team decides to fix it in this branch. The `shared/utils/` convention gap (MEDIUM) requires only a CLAUDE.md update.

An ADR covering the `BatchStatus` shared-domain placement decision has been written to `docs/decisions/0018-batch-status-shared-domain-placement.md`.
