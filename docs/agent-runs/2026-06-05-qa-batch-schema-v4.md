# QA Review v4 — feature/batch-schema-consistency

**Reviewer:** qa-engineer
**Session ID:** qa-batch-schema-v4
**PR / Branch:** feature/batch-schema-consistency
**Date:** 2026-06-05

---

## Verdict: CHANGES REQUESTED

One new blocking regression introduced by the `verify_delivery_screen.dart` fix: the widget test for that screen was not updated alongside the production code change and now fails. All previously blocking findings from v1–v3 are confirmed resolved.

---

## All Blocking Findings — Resolved?

| Finding (v1–v3) | Status |
|---|---|
| `formatBatchId` unit tests — 8 cases | RESOLVED |
| `FoodCategory.fromString` unit tests — 4 cases | RESOLVED |
| `BatchStatus` moved to `shared/domain/entities/batch_status.dart` | RESOLVED |
| `OrderHistoryEntry.displayId` removed from domain | RESOLVED |
| `verify_delivery_screen.dart` still using `batch.id.split('_').last` | RESOLVED in production code — regression introduced in test (see below) |
| `driver_repository_impl.dart` fallback `'local_dining'` | RESOLVED — changed to `'other'` |
| `donorContact` PII field and iOS key | RESOLVED — fully removed, no references remain in `lib/` |

---

## Remaining Findings

### Critical (block merge)

- **`verify_delivery_screen_test.dart` line 81 — test not updated after production code change.**
  The test fixture uses `id: 'batch_001'` (underscore-format, not a UUID) and asserts `find.text('Batch #001')`. With the old `batch.id.split('_').last` logic this produced `001`. With `formatBatchId('batch_001')` the output is `#BATCH001` (dashes-only removed, uppercased, first 8 chars of `BATCH001`), so the displayed string is `'Batch #BATCH001'`. The test now finds 0 widgets matching `'Batch #001'` and fails.
  - Fix: update the test fixture to a UUID-format ID (e.g. `'3f2c1a7b-e5d4-4c8a-9b2f-1234567890ab'`) and update the assertion to `find.text('Batch #3F2C1A7B')`. This matches `formatBatchId` spec and the unit tests already written for it.
  - File: `apps/mobile/test/widget/driver/verify_delivery_screen_test.dart`, line 11 (`id` field) and line 81 (assertion).

### High (fix before release)

- **`order_history_card.dart` — stale category string literals never match.**
  `_iconData`, `_iconBgColor`, and `_iconColor` switch/compare on `'hot_meals'` and `'baked_goods'`. The shared `FoodCategory` enum defines names `bakery`, `produce`, `dairy`, `meat`, `beverages`, `other`. `driver_repository_impl.dart` writes `'other'` as the fallback; Firestore documents normalised through `FoodCategory.fromString` will contain one of those six enum names. The strings `'hot_meals'` and `'baked_goods'` can never be produced by any current code path. Every call to `_iconData` falls through to `Icons.fastfood` and every `_iconBgColor`/`_iconColor` call returns the non-baked-goods branch regardless of input.
  - Risk: cosmetic only — wrong icons/colors for all food categories in the order history card. No crash.
  - Fix: update the switch/comparisons to match the actual enum names: `'bakery'` instead of `'baked_goods'`, add `'produce'` / `'dairy'` / `'meat'` / `'beverages'` / `'other'` cases as appropriate.
  - File: `apps/mobile/lib/features/beneficiary/presentation/widgets/order_history_card.dart`, lines 190–208.
  - Note: test fixtures in `beneficiary_order_history_screen_test.dart`, `beneficiary_org_profile_screen_test.dart`, and `beneficiary_personal_information_screen_test.dart` also use `'hot_meals'`/`'baked_goods'` but do not assert on icon or color behavior, so no test currently fails on this. Updating production code requires no test changes for the icon switch, but fixtures should also be corrected to reflect valid category strings.

### Informational

- `driver_repository_impl.dart` fallback `'other'` — confirmed valid. `FoodCategory.fromString('other')` resolves to `FoodCategory.other`. No issue.
- `donorContact` — zero occurrences in `lib/`, `test/`, and `integration_test/`. Removal is complete.
- `batch.id.split('_').last` — zero occurrences remaining in `lib/`. The fix to `verify_delivery_screen.dart` is the only screen that displayed a formatted batch ID; all other screens only reference `batch.id` for routing or map markers.
- `flutter analyze` — passes with zero issues.

---

## Test Results

- coverage: not measured this pass (targeted regression check)
- **Total: 467 passed, 1 failed**
- failing tests:
  - `test/widget/driver/verify_delivery_screen_test.dart` — `batch identifier card shows id and portions when batch active`
    - Expected: `find.text('Batch #001')` — Found 0 widgets
    - Root cause: fixture ID `'batch_001'` + `formatBatchId` produces `'Batch #BATCH001'` not `'Batch #001'`

---

## Summary

The production-code changes in this PR are correct: `verify_delivery_screen.dart` now calls `formatBatchId`, the fallback category is valid, and `donorContact` is fully purged. However, the widget test for `verify_delivery_screen` was not updated alongside the screen change, creating a direct regression — the test fails on every run. This is not a pre-existing flake; it is a deterministic failure introduced by the PR. The PR cannot merge until the test fixture ID and expected text are updated to match `formatBatchId`'s UUID-based output format. The stale `'hot_meals'`/`'baked_goods'` literals in `order_history_card.dart` are a high-severity cosmetic defect that should be resolved before release but do not block merge on their own.
