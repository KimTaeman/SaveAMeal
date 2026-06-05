# QA Review v3 — feature/batch-schema-consistency
Date: 2026-06-05
Reviewer: qa-engineer

## Verdict: APPROVED (with follow-ups)

All previously blocking findings are resolved. No new blocking issues found.
Three medium-priority follow-up items are logged below. All 468 tests pass.

---

## Previously blocking findings — resolved?

1. **`formatBatchId` unit tests** — RESOLVED.
   `test/unit/shared/utils/batch_id_formatter_test.dart` contains 8 cases covering UUID
   input, dash stripping, case normalisation, short input, empty string, exact-8,
   truncation, and the `#`-prefix invariant. All pass.

2. **`FoodCategory.fromString` unit tests** — RESOLVED.
   `test/unit/shared/domain/entities/food_category_test.dart` contains 4 groups covering
   all known enum names, case-sensitive unknown fallback, empty-string fallback, and an
   exhaustive round-trip over `FoodCategory.values`. Case-sensitivity is explicitly
   documented in the test body (comment: `// case-sensitive`).

3. **`BatchStatus` moved to shared domain** — RESOLVED.
   `lib/shared/domain/entities/batch_status.dart` is a pure Dart file with zero framework
   imports. `lib/features/donor/domain/entities/batch.dart` re-exports it at line 4, so
   existing presentation-layer imports via the donor path continue to resolve.

4. **`OrderHistoryEntry.displayId` removed from domain** — RESOLVED.
   The entity no longer contains a computed display field. `order_history_card.dart` calls
   `formatBatchId(entry.id)` directly at line 54.

---

## Remaining / new findings

### MEDIUM — Stale category strings in `order_history_card.dart` icon/color helpers
- File: `apps/mobile/lib/features/beneficiary/presentation/widgets/order_history_card.dart`
  lines 190, 195, 199, 201
- Detail: `_iconBgColor`, `_iconColor`, and `_iconData` compare `foodCategory` against
  `'baked_goods'` and `'hot_meals'`. These are legacy strings. The canonical `FoodCategory`
  enum now uses `'bakery'`, `'produce'`, `'dairy'`, `'meat'`, `'beverages'`, `'other'`
  (enum `.name` values). Since `OrderHistoryEntry.foodCategory` is populated from
  `FoodCategory.name` via the mapper, the bakery-specific amber icon and `baked_goods`
  branch are permanently dead code. All batches with `category: 'bakery'` will fall through
  to the default `Icons.fastfood` / `ac.success` rendering — no visual differentiation for
  bakery items.
- Recommendation: Update the three private helpers to compare against `'bakery'` (and
  optionally `'other'`, `'produce'`, etc.) to restore the intended icon/colour scheme.
  Add a widget test case that asserts the bakery icon appears for an entry with
  `foodCategory: 'bakery'`.

### MEDIUM — `_extractBatchId` has no unit test
- File: `apps/mobile/lib/features/driver/presentation/screens/pickup_verification_screen.dart`
  lines 39–43
- Detail: `_extractBatchId` is a `static` pure function that strips the
  `saveameal://batch/` URI prefix. The existing widget test
  (`test/widget/driver/pickup_verification_screen_test.dart`) exercises the screen render
  and dialog behaviour but does not exercise URI-stripping. The method has two branches
  (URI present / absent) and a `.trim()` step that are not directly tested. Being a
  `static` method on a private class it cannot be called from outside without reflection.
- Recommendation: Extract `_extractBatchId` to a top-level function in
  `lib/shared/utils/batch_id_formatter.dart` (or a new `uri_utils.dart`) and add 3 unit
  tests: bare ID passthrough, full URI stripped, whitespace trimmed. This also makes the
  formatter and URI utility co-located, which is consistent with how `formatBatchId` is
  structured.

### MEDIUM — No `BatchModel` 12-field round-trip test
- File: `apps/mobile/lib/core/models/batch_model.dart`
- Detail: `BatchModel` has 27 fields (12 required + 15 optional). There is no unit test
  that serialises a fully-populated `BatchModel` to JSON and deserialises it back,
  asserting field-for-field equality. The `_normalise` helper in `FirestoreService` also
  has no direct test; its Timestamp-conversion and nested-map recursion branches are
  exercised only via integration paths.
- Recommendation: Add `test/unit/core/models/batch_model_test.dart` with at least:
  (a) a full round-trip test for all 27 fields, and
  (b) a `_normalise` smoke test using a map containing a fake `Timestamp`-like object (or
  expose `_normalise` as `@visibleForTesting` to enable direct testing).

### LOW — Stale console log in `seed.js` demo setup
- File: `tools/seed/seed.js` line 684
- Detail: The `setupDemo()` function prints:
  `Demo batch: demo_batch_001  (QR code: demo_batch_001)`
  but the `qrCode` field is now `saveameal://batch/demo_batch_001`. The printed message
  will mislead anyone testing manual QR entry by pasting the bare ID — the screen's
  `_extractBatchId` will handle both formats correctly, but the seed script output is
  inaccurate.
- Recommendation: Update the log line to:
  `Demo batch: demo_batch_001  (QR code: saveameal://batch/demo_batch_001)`

### INFO — `pickupWindowStart` / `pickupWindowEnd` format is undocumented
- File: `apps/mobile/lib/features/donor/domain/entities/batch.dart` lines 52–53,
  `apps/mobile/lib/core/models/batch_model.dart` lines 26–27
- Detail: Both `Batch` (domain entity) and `BatchModel` (data model) declare these as
  `String?` with no format comment. Seed data uses `'HH:mm'` strings (e.g. `'14:00'`).
  No test or comment documents this expectation. If a caller passes an ISO-8601 datetime
  string instead, the UI will display it verbatim.
- Recommendation: Add a doc comment on both fields stating the expected format
  (`'HH:mm'` local time string) and add a unit test or assertion in the mapper that
  validates the format on parse. No blocking impact today — this is a pre-emptive
  correctness guard.

---

## Coverage assessment

- New unit tests added this pass: 12 cases across 2 files.
  - `batch_id_formatter_test.dart`: 8 cases, full contract coverage.
  - `food_category_test.dart`: 4 groups (exhaustive), round-trip confirmed.
- `_extractBatchId`: 0 direct unit tests (see MEDIUM finding above).
- `BatchModel` round-trip: 0 tests (see MEDIUM finding above).
- `_normalise`: 0 direct tests (see MEDIUM finding above).
- `getBeneficiaries` / `streetAddress` fix: exercised structurally in
  `organization_profile_screen_test.dart` (uses `streetAddress` field), but no dedicated
  datasource unit test verifying the `data['streetAddress']` read path.
- Total test count: **468 tests, all passing**.

---

## Summary

The three blocking v2 findings are fully resolved. The two new v3 additions
(`_extractBatchId` URI stripping and seed data `qrCode` migration) are correctly
implemented. The `BatchStatus` move and `displayId` removal are clean with no
presentation-layer import breakage. No hardcoded colors, text styles, or spacing
magic numbers were found in the changed files; theming is consistently via `cs.*`,
`ac.*`, `textTheme.*`, and `Spacing.*` constants.

Three medium-priority gaps remain open: (1) stale legacy category strings in
`order_history_card.dart` that silently suppress the intended bakery icon/color, (2) no
unit test for the `_extractBatchId` two-branch logic, and (3) no `BatchModel` round-trip
test covering all 27 fields. These are not blocking but should be addressed before the
next feature that touches the Firestore mapping layer.

**Verdict: APPROVED** — branch is mergeable. Open a follow-up ticket for the three MEDIUM
items.
