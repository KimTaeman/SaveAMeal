# Architect Review v3 — feature/batch-schema-consistency
Date: 2026-06-05
Reviewer: architect

## Verdict: APPROVED

All three blocking issues from v1/v2 are verified resolved. One pre-existing HIGH finding (pickupWindowStart/End typing) remains unresolved but was explicitly deferred in v2; it is re-listed here for tracking. One new pre-existing domain-layer violation is flagged (BatchSummary importing a data-layer model) — this is not introduced by this PR, but surfaces during the audit and is noted as HIGH for follow-up.

---

## Previously blocking findings — resolved?

### BLOCKING 1 — RESOLVED
`displayId` getter removed from `OrderHistoryEntry`. The entity file now has zero imports (confirmed: first line is a comment, no import statements). `formatBatchId(entry.id)` is called correctly in `order_history_card.dart` line 54, `delivery_history_row.dart` line 25, `rate_delivery_screen.dart` line 105, and multiple donor screens — all presentation layer. Domain entity is clean.

### BLOCKING 2 — RESOLVED
`BatchStatus` now lives at `lib/shared/domain/entities/batch_status.dart` (confirmed: file contains only a comment and the pure-Dart enum). `batch.dart` (donor domain) correctly uses `import` + `export` of the shared path. `firestore_service.dart` line 7 imports from `package:saveameal/shared/domain/entities/batch_status.dart` — no longer from `features/donor/`. ADR-0018 is written and covers this decision.

### BLOCKING 3 — RESOLVED
`test/unit/shared/utils/batch_id_formatter_test.dart` exists and contains 8 test cases in a `formatBatchId` group, covering: canonical UUID, no-dash input, mixed-case, short inputs (7-char, 3-char), empty string, already-uppercase input, and truncation. The `#` prefix invariant is also asserted. Test coverage is adequate.

---

## Remaining / new findings

### [HIGH] BatchSummary (driver domain entity) imports a data-layer model

- **File/line:** `apps/mobile/lib/features/driver/domain/repositories/driver_repository.dart` line 2
- **Rule:** Domain layer — zero Flutter or backend imports. Domain must not depend on the data layer.
- **Detail:** `BatchSummary` is declared in the driver domain and carries `final List<BatchItemModel> items`, where `BatchItemModel` is a Freezed model from `lib/core/models/batch_item_model.dart`. `BatchItemModel` carries `freezed_annotation` and JSON serialisation code (`fromJson`). A domain entity must not hold a reference to a data-layer type; the dependency arrow runs the wrong way. This was present before this PR and is not introduced here, but it is surfaced by the audit. The violation means the driver domain layer cannot be used without pulling in Freezed-generated code, breaking the "pure Dart domain" invariant.
- **Recommendation:** Introduce a `BatchItem` pure-Dart value object in `lib/features/donor/domain/entities/batch_item.dart` (one already exists for the donor feature at that path based on `batch.dart`'s import of it — confirm it is pure Dart). Replace `BatchItemModel` in `BatchSummary` with that entity, and map at the data layer boundary in `driver_repository_impl.dart`. This should be raised as a separate ticket rather than blocking this PR, since it pre-dates the current branch.

### [HIGH] pickupWindowStart / pickupWindowEnd typed as String? in domain entities (deferred, not resolved)

- **File/line:** `apps/mobile/lib/features/donor/domain/entities/batch.dart` lines 52–53; `apps/mobile/lib/features/driver/domain/repositories/driver_repository.dart` lines 31–32
- **Rule:** Domain entities should model business concepts accurately. A time window is a temporal value, not an opaque string.
- **Detail:** Both the `Batch` entity and the `BatchSummary` entity carry these fields as `String?`. The driver map screen and job detail screen interpolate them directly into UI strings without parsing. Downstream: if validation, ordering, or arithmetic is ever needed on these fields (e.g., "is the pickup window still open?"), every call site will need ad-hoc parsing. Confirmed still unresolved — deferred from v2 explicitly. The seed data stores these as strings (`"09:00"` style) so a breaking schema migration is not free.
- **Recommendation:** Track as a follow-up issue. When addressed, change the type to `DateTime?` (absolute) or introduce a `TimeOfDay`-equivalent pure-Dart value object. The data layer mapper absorbs the parse. No action required to unblock this PR.

### [MEDIUM] shared/utils/ directory scope not documented in CLAUDE.md

- **File/line:** `apps/mobile/lib/shared/utils/batch_id_formatter.dart`
- **Rule:** Project conventions should be documented so contributors know the intended scope of each directory.
- **Detail:** `shared/utils/` was flagged as an undocumented new directory in v1. As of v3 it still does not appear in the architecture section of `CLAUDE.md` or in any ADR. The directory now has one file and is called from seven presentation-layer call sites, which means it is established practice. Without a documented scope, the directory risks accumulating unrelated helpers.
- **Recommendation:** Add a one-line entry under the Architecture section of `CLAUDE.md`: `shared/utils/ — pure-Dart, presentation-adjacent helpers (formatters, validators, extension helpers). No Flutter or backend imports.` This does not block merge but should be completed in the same sprint.

### [LOW] import + export pattern in batch.dart carries a minor lint risk

- **File/line:** `apps/mobile/lib/features/donor/domain/entities/batch.dart` lines 2–4
- **Rule:** No duplicate-export lint warnings.
- **Detail:** The file both imports and re-exports `batch_status.dart`. This is valid Dart. The Dart analyzer does not emit a warning for importing and re-exporting the same URI from the same file. The only edge case is if another file in the same library also exports `batch_status.dart` via a different path — that would cause a "duplicate export" warning at the consumer, not here. Given that `shared/domain/entities/batch_status.dart` is not currently part of any barrel file, no conflict exists. This is informational only.
- **Recommendation:** No action required. If a `shared/domain/entities/shared_domain.dart` barrel is introduced later, ensure `batch_status.dart` is only exported once.

### [INFO] seed.js qrCode format is consistent with app URI scheme

- **File/line:** `tools/seed/seed.js` lines 223, 244, 264, 283, 303, 328, 350, 370, 391, 412, 433, 456, 477, 650
- **Rule:** Seed data should match the format the app writes and reads.
- **Detail:** All hardcoded batch records use `saveameal://batch/<id>` and the dynamic template at line 650 uses the same pattern. `_extractBatchId()` in `pickup_verification_screen.dart` strips the `saveameal://batch/` prefix before comparing against `activeBatch.id`, so the round-trip is correct for both the URI format and bare IDs. No discrepancy found.
- **Recommendation:** No action required.

### [INFO] _extractBatchId is a private static method on a ConsumerState subclass — no layer concern

- **File/line:** `apps/mobile/lib/features/driver/presentation/screens/pickup_verification_screen.dart` lines 38–43
- **Rule:** Presentation layer may contain formatting/parsing helpers when they are widget-scoped.
- **Detail:** `_extractBatchId` is `static`, takes a `String`, and returns a `String`. It has no widget dependencies and no `BuildContext`. Placing it as a private static on the state class is a legitimate presentation-layer scoping choice — it is not accessible outside the file, it does not leak into domain, and it performs URI stripping that is specific to the QR scanning interaction. The alternative (moving it to `shared/utils/`) would make sense if other screens needed the same logic, but currently only this screen parses the URI. No architecture concern.
- **Recommendation:** No action required. If a second consumer appears, extract to `shared/utils/batch_uri_parser.dart`.

---

## Summary

The three blocking issues from v2 are cleanly resolved. Domain entity `OrderHistoryEntry` is now import-free. `BatchStatus` is correctly placed in `shared/domain/entities/` and re-exported from `batch.dart` without lint risk. Unit tests for `formatBatchId` are present with 8 cases. The seed data URI format matches `_extractBatchId`'s parser exactly. The branch is safe to merge.

Two items require follow-up tickets but do not block this PR: the `BatchSummary`-imports-`BatchItemModel` domain violation (HIGH, pre-existing) and the `pickupWindowStart`/`End` String typing (HIGH, explicitly deferred). One item requires a CLAUDE.md documentation update in the current sprint: `shared/utils/` directory scope (MEDIUM).
