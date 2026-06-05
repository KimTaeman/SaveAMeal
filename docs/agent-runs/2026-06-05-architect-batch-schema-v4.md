# Architect Review v4 — feature/batch-schema-consistency
Date: 2026-06-05
Reviewer: architect
Branch: feature/batch-schema-consistency
Pass: 4 of 4 (final)

---

## Verdict: APPROVED

All previously blocking findings are resolved. The two remaining items below are carry-forward non-blockers that must be tracked as follow-up tickets.

---

## All blocking findings — resolved?

| Finding (prior pass) | Status |
|---|---|
| `BatchStatus` domain purity | RESOLVED — `shared/domain/entities/batch_status.dart` has zero imports; pure Dart confirmed |
| `OrderHistoryEntry` display logic in domain | RESOLVED — entity has zero imports; no display logic present |
| Unit tests for `formatBatchId` and `FoodCategory.fromString` | RESOLVED — tests present |
| `verify_delivery_screen.dart` inconsistent batch ID format | RESOLVED — line 81 confirmed: `'Batch ${formatBatchId(batch.id)}'` |
| `driver_repository_impl.dart` fallback `'local_dining'` | RESOLVED — changed to `'other'` |
| iOS API key hardcoded in `AppDelegate.swift` | RESOLVED — de-hardcoded |
| `donorContact` field present in entities/models/mappers/screens/seed | RESOLVED — grep over `apps/mobile/lib/**/*.dart` returns zero matches |

---

## Audit scope results

### 1. Final batch ID consistency sweep

`formatBatchId` is imported and called in every surface that renders a short batch ID to the user:

- `verify_delivery_screen.dart` line 81 — CONFIRMED fixed
- `delivery_completed_screen.dart` — does NOT display a short batch ID at all; it shows `batch.totalPortions` and `batch.beneficiaryName` in prose. No formatter call is needed or expected.
- `driver_map_screen.dart` — `batch.id` appears only at line 81 as `MarkerId(batch.id)`. `MarkerId` is an internal Google Maps SDK key, not user-visible text. Using the raw UUID here is correct; applying `formatBatchId` would be wrong.
- `claim_rescue_screen.dart` — `batch.id` appears only in a GoRouter navigation path string (`/driver/job/${batch.id}`). Raw UUID is required for routing; this is correct.

All eight presentation files that render `formatBatchId` to users import `package:saveameal/shared/utils/batch_id_formatter.dart` directly. No stray `split('_').last` patterns remain anywhere in the codebase.

**Result: batch ID consistency is complete and correct.**

### 2. `donorContact` complete removal

Grep of `apps/mobile/lib/**/*.dart` (excluding `.g.dart`) returns zero matches. The field is gone from all entities, models, mappers, screens, and seed data.

**Result: removal is complete.**

### 3. `shared/utils/batch_id_formatter.dart` — scope documented?

`CLAUDE.md` does not document the `shared/utils/` directory. The architecture section describes `shared/widgets/` and `shared/theme/` but `shared/utils/` is absent. Eight files already import from this path. Without documentation, future contributors will be uncertain whether to place cross-feature pure-Dart utilities here or in `core/`.

This is a non-blocking documentation gap, not a code defect. Tracked below.

### 4. `shared/domain/entities/batch_status.dart` — pure Dart confirmed?

File has zero import statements. It contains only the `BatchStatus` enum definition. Pure Dart confirmed.

### 5. `batch.dart` import + export pattern

`features/donor/domain/entities/batch.dart` line 2 imports `batch_status.dart` and line 4 re-exports it:

```dart
import 'package:saveameal/shared/domain/entities/batch_status.dart';
export 'package:saveameal/shared/domain/entities/batch_status.dart';
```

The Dart analyzer does not flag an import+export of the same URI as a lint error; it is legal and intentional — callers that `import batch.dart` get `BatchStatus` transitively. However, it creates an implicit secondary source of truth for `BatchStatus`. Any file that resolves `BatchStatus` through the re-export is technically depending on `donor/domain`, not `shared/domain`, which defeats the purpose of ADR-0018. This is a low-severity structural concern, not a blocker for this PR.

### 6. ADR-0018

Present at `docs/decisions/0018-batch-status-shared-domain-placement.md`. Status is `PROPOSED`. The ADR should be updated to `ACCEPTED` now that implementation is merged. This is an administrative follow-up, not a code blocker.

### 7. Pre-existing HIGH — `BatchSummary` imports `BatchItemModel`

Confirmed still present in `features/donor/data/repositories/donor_repository_impl.dart` lines 2, 146, 154. The data repository imports `BatchItemModel` from `core/models/` and uses it in two private mapper methods (`_toBatchItem`, `_fromBatchItem`). This is the data layer importing a data-layer model — the direction is correct (data → data). The earlier HIGH flag was a misnaming concern, not a layer violation. No action required for this PR.

---

## Remaining findings (non-blocking, follow-up tickets required)

**LOW-1 — `shared/utils/` not documented in `CLAUDE.md`**
- Violation: `CLAUDE.md` architecture section omits `shared/utils/`; eight files import from it.
- Why it matters: contributors will not know whether cross-feature utility functions belong in `shared/utils/` or `core/`; duplication risk.
- Fix: add `shared/utils/` to the architecture table in `CLAUDE.md` with a one-line description: "cross-feature pure-Dart utility functions (no Flutter imports)".

**LOW-2 — ADR-0018 status still `PROPOSED`**
- Fix: update status field to `ACCEPTED` and add a one-line note recording the merge date.

**LOW-3 — `batch.dart` re-exports `BatchStatus` from shared domain**
- Violation: callers importing `batch.dart` receive `BatchStatus` transitively via donor domain rather than directly from `shared/domain`.
- Why it matters: weakens the intent of ADR-0018 over time; callers may form an implicit dependency on the re-export path and miss the canonical shared location.
- Fix (next sprint): remove the `export` line from `batch.dart`; update any callers that relied on the re-export to import `shared/domain/entities/batch_status.dart` directly. Estimated impact: grep for `import.*batch.dart` and cross-reference with `BatchStatus` usage — likely 2–4 files.

---

## Summary

All four blocking issues from prior passes are confirmed resolved. The domain layer is pure Dart with zero framework or backend imports. `donorContact` is fully excised. `formatBatchId` is applied consistently across every user-facing surface; the two cases where raw UUID is used (`MarkerId`, GoRouter path) are architecturally correct. The re-export of `BatchStatus` through `batch.dart` is a low-severity structural smell to clean up in the next sprint, not a merge blocker. ADR-0018 administrative update and `CLAUDE.md` documentation gap are housekeeping items.

**This branch is approved to merge.**
