# QA Review — feature/batch-schema-consistency
Date: 2026-06-05
Reviewer: qa-engineer

## Verdict: CHANGES REQUESTED

---

## Findings

### [BLOCKING] `formatBatchId` has no unit tests and silently degrades on short/empty input

- File: `apps/mobile/lib/shared/utils/batch_id_formatter.dart`
- Detail: The function is called on every batch card render and on every search keystroke. No unit test exists for it anywhere in `test/`. The empty-string case (`formatBatchId('')`) returns `'#'` — no exception, no assertion, just a bare `#` rendered as the batch ID. A string shorter than 8 chars after dash-removal (e.g. a 7-char ID like `'abc4092'` used in the order-history test) returns a `#`-prefixed string that is fewer than 9 chars total. This is undocumented behaviour. Because the function is a pure utility with no Flutter dependency, a unit test is trivial and must be added before merge.
- Recommendation: Add `test/unit/shared/utils/batch_id_formatter_test.dart` covering: (1) canonical 36-char UUID produces 9-char `#XXXXXXXX` result; (2) 7-char input produces `#XXXXXXX` (not a crash); (3) empty string produces `'#'` — or change the implementation to throw/assert on empty input if that is the intended contract; (4) input that already contains no dashes; (5) mixed-case input uppercased correctly.

### [BLOCKING] `FoodCategory.fromString` has no unit tests

- File: `apps/mobile/lib/shared/domain/entities/food_category.dart`
- Detail: `FoodCategory.fromString` is the fallback factory for all Firestore category strings, including unknown/future values. No unit test verifies the happy path (known value round-trips) or the fallback (`FoodCategory.other` returned for unrecognised input). The function is invoked via `_toBatchItem` in `donor_repository_impl.dart` on every Firestore batch read.
- Recommendation: Add `test/unit/shared/domain/entities/food_category_test.dart` covering: all known enum names, an unknown string (expects `FoodCategory.other`), and an empty string (expects `FoodCategory.other`).

### [HIGH] `Batch` entity 12-new-field round-trip is untested

- File: `apps/mobile/lib/features/donor/data/repositories/donor_repository_impl.dart` (`_toBatch` / `_fromBatch`)
- Detail: Twelve new optional fields were added to `Batch` in this PR: `volunteerName`, `beneficiaryName`, `beneficiaryAddress`, `donorName`, `donorContact`, `pickupWindowStart`, `pickupWindowEnd`, `specialInstructions`, `photoUrl`, `pickupPhotoUrl`, `qrCode`, `deliveryNotes` (plus `rating`, `feedback`). The existing use-case unit tests (`watch_active_batches_usecase_test.dart`, `watch_all_batches_usecase_test.dart`, `watch_batch_by_id_usecase_test.dart`) mock the repository and never exercise `_toBatch`/`_fromBatch` mapping. There is no data-layer unit test that constructs a fully-populated `BatchModel` and asserts that all new fields survive `_toBatch`. A silent field-drop (e.g. a typo in a mapping line) would be invisible.
- Recommendation: Add a unit test in the data layer (e.g. `test/unit/features/donor/data/donor_repository_impl_mapping_test.dart`) that populates every field of a `BatchModel` and asserts equality of the resulting `Batch`. `_fromBatch` round-trip (domain → model → domain) should also be exercised.

### [HIGH] Search filter regression: `#` prefix breaks users who type raw hex prefixes

- File: `apps/mobile/lib/features/donor/presentation/screens/donor_history_screen.dart` (line 78)
- Detail: The new search predicate is `formatBatchId(b.id).toLowerCase().contains(q)`. `formatBatchId` prepends `#`. A user who types `'abcd'` will still match because `'#abcdefgh'` contains `'abcd'`. However, if a user types `'#abc'` they now match, whereas previously they would not. More critically: the old implementation searched the first 4 chars of the raw UUID. If a donor's UI previously displayed (and they memorised) a different short form of the same UUID, e.g. the first 4 chars before the first dash, their memorised prefix may now be at a different position in the formatted ID or may now be obscured by the dash-strip. The existing widget test (`'search filters by batch short ID'`) only verifies filtering works with 8-char IDs that have no dashes. It does not test that a UUID such as `'ab12-cd34-...'` matches when the user types `'ab12'` (it should: `'#AB12CD34'` contains `'ab12'` after lowercasing). The test should be extended to cover at least one UUID-format ID to confirm dashes are stripped before search.
- Recommendation: Extend the donor history search test with an additional case using a UUID-format `id` (e.g. `'ab12cd34-0000-0000-0000-000000000000'`) and assert that searching `'ab12'` matches it. Document in a code comment that the `#` prefix is searchable — i.e. a user can type `#AB12` to narrow results.

### [HIGH] `getBeneficiaries()` address field change is untested

- File: `apps/mobile/lib/services/firestore_service.dart` (line 407)
- Detail: The field read was changed from `data['address']` to `data['streetAddress']`. No test covers `getBeneficiaries()`. If the Firestore schema still has documents with the old field name `address`, those documents will now silently return `null` for `BeneficiaryModel.address`. The PR description does not confirm a migration was run.
- Recommendation: (1) Add a unit test for `getBeneficiaries()` that exercises the field mapping; (2) Confirm whether existing Firestore documents need a backfill migration from `address` to `streetAddress`.

### [HIGH] `watchActiveDeliveriesForBeneficiary`, `watchVolunteerQueue` normalisation is untested

- File: `apps/mobile/lib/services/firestore_service.dart` (lines 116-127, 160-201)
- Detail: The diff adds `_normalise(...)` calls to these three query paths. No test covers any `FirestoreService` method that reads `BatchModel`s through these specific streams. A Firestore `Timestamp` in any field returned by these queries would previously have caused a `fromJson` parse error at runtime; with the fix the timestamps are now correctly converted. The regression test ensuring this is absent.
- Recommendation: Add unit tests using mock `QuerySnapshot` data containing `Timestamp` values for `claimedAt`, `pickedUpAt`, `deliveredAt`, `createdAt`, `updatedAt` and assert that `BatchModel.fromJson` succeeds via the normalise path for each of the three affected methods.

### [MEDIUM] `pickupWindowStart` / `pickupWindowEnd` typed as `String?` — rendered directly in UI without parsing

- File: `apps/mobile/lib/features/driver/presentation/screens/job_detail_screen.dart` (line 77), `driver_map_screen.dart` (line 175)
- Detail: Both screens render the window as `'${batch.pickupWindowStart} – ${batch.pickupWindowEnd}'` with no parsing or formatting. If Firestore stores ISO-8601 strings (e.g. `'2026-06-05T14:00:00.000Z'`), the driver sees a raw ISO string in the UI. There is no `DateFormat` applied. `String?` also means there is no compile-time contract on the expected format — a caller could store `'2 PM'`, a timestamp string, or a locale-formatted time.
- Recommendation: Decide on a canonical format (e.g. `DateTime?`) and parse/format at the presentation layer. At minimum, add a display helper that strips the ISO components down to a human-readable time. If `String?` is intentional (human-entered text), document this explicitly.

### [MEDIUM] Donor history search test uses 8-char IDs without dashes — does not validate UUID path

- File: `apps/mobile/test/widget/features/donor/donor_history_screen_test.dart` (line 174-186)
- Detail: The search test uses IDs `'aaaaaaaa'` and `'bbbbbbbb'` — no dashes, exactly 8 chars. This exercises only the trivial path through `formatBatchId`. Real Firestore document IDs are 20-char auto-IDs (not UUID format), but the app uses UUID-format IDs from `const Uuid().v4()` (based on `create_batch_usecase_test.dart`). The test does not verify that a real UUID such as `'3f2c1a7b-e5d4-4c8b-9f1a-2b3c4d5e6f7a'` matches when the user types `'3F2C1A7B'` or `'3f2c1a7b'`.
- Recommendation: Add one test case with a full UUID `id` to confirm dash-stripping and case-folding both work in the search predicate.

### [LOW] `BatchStatus.cancelled` missing from `_accentColor` switch in `_BatchHistoryCard`

- File: `apps/mobile/lib/features/donor/presentation/screens/donor_history_screen.dart` (line 346-352)
- Detail: The `_accentColor` switch handles `delivered|closed`, `open|claimed|pickedUp`, and a catch-all `_`. The `cancelled` status introduced in `batch.dart` falls through to `_ => ac.danger` implicitly. This is functionally correct but unintentional — `cancelled` should arguably share the `completed` color or have its own. A lint warning for non-exhaustive switch is suppressed by the wildcard.
- Recommendation: Add an explicit `BatchStatus.cancelled` arm to make intent clear and protect against future status additions.

### [LOW] `OrderHistoryEntry` domain entity imports a shared utility — borderline domain-layer purity

- File: `apps/mobile/lib/features/beneficiary/domain/entities/order_history_entry.dart` (line 3)
- Detail: The entity imports `package:saveameal/shared/utils/batch_id_formatter.dart` to implement the `displayId` getter. The `batch_id_formatter` is pure Dart (no Flutter import), so the domain-layer rule ("zero Flutter or backend imports") is not technically violated. However, placing formatting logic inside a domain entity couples display concerns to the domain. If the display format changes, the entity must change.
- Recommendation: Consider moving the `formatBatchId` call to the presentation layer (e.g. inside the `OrderHistoryCard` widget or a view model) and keeping `OrderHistoryEntry.displayId` either absent or returning the raw `id`. This is a design preference and not a blocker, but aligns better with strict Clean Architecture.

### [INFO] Test assertion correctness — `'Order #ABC4092'` for `id: 'abc4092'`

- File: `apps/mobile/test/widget/features/beneficiary/beneficiary_order_history_screen_test.dart` (line 126-127)
- Detail: Tracing `formatBatchId('abc4092')`: `clean = 'ABC4092'` (7 chars, no dashes to strip), `clean.length >= 8` is false, so `short = clean.substring(0, 7) = 'ABC4092'`, returns `'#ABC4092'`. `displayId = '#ABC4092'`. Card renders `'Order #ABC4092'`. Test expects `'Order #ABC4092'`. The assertion is correct. Similarly `id: 'xyz4105'` → `'#XYZ4105'` → `'Order #XYZ4105'`. Both assertions are correct.

### [INFO] `BatchStatus` deduplication — import update in test file is correct

- File: `apps/mobile/test/unit/features/beneficiary/intake_request_detail_mapper_test.dart` (line 4)
- Detail: The explicit `show BatchStatus` import from the domain `batch.dart` was added correctly. No test logic changed; the mapper test still passes all 7 cases. No issue.

---

## Coverage gaps

| Changed code | Test exists? | Gap |
|---|---|---|
| `batch_id_formatter.dart` — `formatBatchId` | No | No unit test at all |
| `FoodCategory.fromString` | No | No unit test at all |
| `Batch` 12 new fields, `_toBatch`/`_fromBatch` mapping | No | No data-layer mapping test |
| `firestore_service.dart` — `getBeneficiaries()` field rename | No | No service unit test |
| `firestore_service.dart` — `watchActiveDeliveriesForBeneficiary` normalise fix | No | No service unit test |
| `firestore_service.dart` — `watchVolunteerQueue` (×2) normalise fix | No | No service unit test |
| `donor_history_screen.dart` — search uses `formatBatchId` | Partial | Test exists but uses trivial 8-char no-dash IDs; UUID format not covered |
| `OrderHistoryEntry.displayId` computed getter | Indirect | Covered by widget test assertions; no isolated unit test of the getter itself |
| `BatchStatus` deduplication | Yes | Mapper test updated correctly — no gap |

---

## Summary

The PR makes correct functional changes — the `_normalise` fixes are necessary, the `BatchStatus` deduplication is clean, and the `displayId` computed getter is architecturally straightforward. The test assertions that were updated (`beneficiary_order_history_screen_test.dart`) are verified correct by manual trace.

However, the PR introduces a new shared utility (`batch_id_formatter.dart`) and a new enum factory (`FoodCategory.fromString`) with zero unit test coverage. Three Firestore service methods that received bug fixes have no regression tests. The `Batch` entity gained 12 new fields whose mapping is entirely untested. These are not cosmetic gaps — the normalise fix and the field rename are exactly the kind of silent runtime error that a regression test is designed to catch.

The search-filter behaviour change is not a breaking regression for the common case (searching a prefix still works), but the existing test does not validate the UUID-with-dashes path that real production data follows.

CHANGES REQUESTED: add unit tests for `formatBatchId`, `FoodCategory.fromString`, `_toBatch` field round-trip, and at least one test per fixed Firestore method before merge.
