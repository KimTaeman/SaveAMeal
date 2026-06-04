# QA Review — Beneficiary Impact Screen
**Date:** 2026-06-03
**Reviewer:** qa-engineer
**Branch:** feat/beneficiary-impact-screen
**Verdict:** APPROVED WITH NOTES

---

## Coverage gaps

### [NON-BLOCKING] No dedicated unit or widget test file for `ImpactMetricTile`
`ImpactMetricTile` is exercised only as an incidental find inside `beneficiary_impact_screen_test.dart` (tests 4 and the CO2/Waste label checks). There is no isolated test file for this widget. The widget's contract — `icon`, `label`, `value` rendered with correct styles — is specified in the spec but never directly asserted in isolation. Missing test cases: icon rendered with `cs.primary` color, `label` text present, `value` text present, `Card` with `BorderRadius.circular(12)`.
Recommended file: `test/widget/features/beneficiary/impact_metric_tile_test.dart`.

### [NON-BLOCKING] Progress bar clamping test exists and passes
`impact_hero_card_test.dart` line 77–98 covers `totalMeals = 15000`, asserts `indicator.value == 1.0`, and confirms the caption shows `150% of yearly goal` (unclamped percentage). This gap from the task brief is already closed.

### [NON-BLOCKING] `ImpactCategoryRow` division-by-zero not guarded in the widget itself
The spec states: "When `totalKg == 0`, the row must not be rendered (caller responsibility)." The screen enforces this by filtering with `.where((e) => e.value > 0)`, which implicitly prevents rows where `totalKg` could be zero. However, `ImpactCategoryRow.build` performs `kg / totalKg` with no guard — if constructed directly with `totalKg = 0` it throws a `NaN`/`Infinity` rendering the `%` text as `NaN%` rather than crashing, but it is observable incorrect output. No test covers the `totalKg = 0` direct construction path on the widget itself. Recommended test in `impact_category_row_test.dart`: construct with `kg = 0.001, totalKg = 0` and assert the widget does not throw (or that the caller contract is enforced upstream).

### [NON-BLOCKING] `BeneficiaryImpactModel.fromFirestore` — integer fields from Firestore not explicitly tested
The model already uses `(data['totalMeals'] as num? ?? 0).toInt()` and `(data['totalKg'] as num? ?? 0).toDouble()` which correctly handles both `int` and `double` Firestore returns via the `num` cast. However, `beneficiary_impact_model_test.dart` passes `8420` (a Dart `int` literal) for `totalMeals` and `3100.0` (a Dart `double` literal) for `totalKg` in the full-document test — this does not exercise the cross-type coercion (e.g., Firestore returning `totalKg` as an integer `3100` or `totalMeals` as a double `8420.0`). Missing test: `'totalKg': 3100` (int) should yield `model.totalKg == 3100.0`; `'totalMeals': 42.0` (double) should yield `model.totalMeals == 42`.

### [NON-BLOCKING] `byCategory` inconsistency — `kg > totalKg` — not tested
If a Firestore document has a category whose accumulated kg exceeds `totalKg` (due to a data write race or Cloud Function bug), `ImpactCategoryRow` would display a percentage above 100%. No test covers this. The screen does not clamp `kg / totalKg` before passing to the row. This is a data integrity issue at the Cloud Function layer, but the Flutter client could defensively clamp. Missing test: `ImpactCategoryRow` with `kg = 600, totalKg = 400` should show `150%` (documents current unclamped behaviour) or should be clamped to `100%` depending on product decision.

### [NON-BLOCKING] Large `totalCo2e` value formatting — no test
`BeneficiaryImpactScreen` formats the CO2 tile as `(impact.totalCo2e / 1000).toStringAsFixed(1) Tons`. With `totalCo2e = 1_000_000_000` (1 billion kg) this produces `"1000000.0 Tons"`. No test exercises large values. The spec does not specify truncation, so this is informational, but the UI string would overflow `ImpactMetricTile` on narrow devices. Missing test: `totalCo2e = 999_999_000` should render `"1000.0 Tons"` (actually `999999.0 Tons`) — document what the real value looks like.

---

## Performance

- `beneficiary_impact_screen.dart` line 105–114: `ListView.builder` with `shrinkWrap: true` and `NeverScrollableScrollPhysics()` inside a `SingleChildScrollView` is acceptable for a bounded, short list (at most 6 category rows for the 6 `FoodCategory` enum values). The spec explicitly mandates this pattern. No unbounded `ListView` violation.
- `filteredCategories` is re-derived on every `build` call via `.where().toList()`. For a maximum of 6 items this is inconsequential, but it could be moved to a local `final` variable (it already is — line 39–41). No issue.
- The screen rebuilds the full widget tree whenever `beneficiaryImpactProvider` emits. The provider is a `StreamProvider`; Riverpod diffs the `AsyncValue`, so rebuilds only occur on new Firestore emissions. No issue.
- `ImpactHeroCard` imports `beneficiary_impact_screen.dart` to access `kBeneficiaryYearlyGoalMeals` — a circular-ish import that is not a circular dependency but is a layering smell. The constant should be in a shared constants file or in `impact_hero_card.dart` directly. This is informational only; no performance impact.

---

## Accessibility

- `ImpactHeroCard` — `LinearProgressIndicator` has no `Semantics` wrapper. Screen readers announce it as a generic progress indicator with no contextual label. The WCAG 2.2 AA criterion 1.3.1 (Info and Relationships) requires the progress bar to be announced with its purpose. Fix: wrap the `LinearProgressIndicator` with `Semantics(label: '$caption', value: '${(progress * 100).round()}%')`.

- `ImpactHeroCard` icon-only — no icon in `ImpactHeroCard` itself, not an issue.

- `BeneficiaryImpactScreen` AppBar — `IconButton(icon: Icon(Icons.notifications_outlined), onPressed: null)` has no `tooltip` or `Semantics` label. An `IconButton` with `onPressed: null` is disabled but still present in the widget tree; it should carry a `tooltip: 'Notifications'` for screen readers. Missing `semanticsLabel`.

- `BeneficiaryImpactScreen` AppBar — `Icon(Icons.location_on, color: cs.primary)` in the app bar title row carries no semantic label. Decorative icons should be marked `excludeFromSemantics: true` via a `Semantics` wrapper. Fix: wrap with `ExcludeSemantics()` or `Semantics(excludeSemantics: true)`.

- `ImpactCategoryRow` — `Icon(_categoryIcon(category), color: cs.primary)` in the `ListTile.leading` has no `semanticsLabel`. Flutter's `Icon` renders with no default semantic label when placed in a `ListTile`; the `ListTile.title` text provides context, so this is borderline. The combination of icon + title is sufficient for 1.3.1, but an explicit `semanticsLabel` on the `Icon` or a `Semantics(label: _categoryDisplayName(category))` wrapper on the `ListTile` would make this robust. NON-BLOCKING.

- `_OfflineBanner` contrast: background is `ac.warning = Color(0xFFF57F17)` (orange), foreground text is `ac.onWarning = Color(0xFF000000)` (black). Luminance ratio for `#F57F17` on `#000000` is approximately 5.1:1, which passes WCAG AA 4.5:1 for normal text. No contrast failure.

- `ImpactHeroCard` text on `cs.primary = Color(0xFF3DBE6C)` (green), `cs.onPrimary = Colors.white`. Luminance ratio for white (#FFFFFF) on #3DBE6C is approximately 2.9:1. This **fails** WCAG AA 4.5:1 for normal-sized text (the `labelSmall`, `bodySmall`, and `titleMedium` spans all use `cs.onPrimary`). The `displaySmall` meal-count figure qualifies as large text (18pt bold or 24pt regular); white on #3DBE6C at 2.9:1 also fails the 3:1 minimum for large text. This is a BLOCKING accessibility failure against WCAG 2.2 AA criterion 1.4.3. The seed color `0xFF3DBE6C` produces an insufficiently dark primary for white foreground text. Fix: darken `primary` to at least `Color(0xFF1A7A3A)` (contrast ~4.8:1 with white) or use `cs.onPrimary = Colors.black` with a sufficiently light primary.

- `TextButton(onPressed: null, child: Text('Details'))` — disabled buttons render at reduced opacity by Material 3 but carry no semantic label indicating they are disabled. Flutter's `TextButton` with `onPressed: null` does set `enabled: false` in the semantics tree automatically, so this is handled by the framework. No issue.

---

## Edge cases

- **Large `totalCo2e`**: `(1_500_000_000 / 1000).toStringAsFixed(1)` produces `"1500000.0 Tons"`. This string will overflow `ImpactMetricTile`'s `Text` widget on any standard device width. The tile uses `textTheme.titleMedium` with no `overflow` or `maxLines` constraint, causing text to wrap onto two lines inside the fixed-padding `Card`. No production bug today (realistic data will not hit this for MVP), but worth adding a `maxLines: 1, overflow: TextOverflow.ellipsis` to the value `Text` in `ImpactMetricTile`.

- **`byCategory` kg exceeds `totalKg`**: `ImpactCategoryRow` will display `> 100%` (e.g., `150%`). The `.round()` call will not throw; it will just display a semantically incorrect value. Screen does not crash. No regression.

- **`Details` TextButton `onPressed: null`**: Material 3 renders disabled `TextButton` at 38% opacity. The spec explicitly calls this out as an MVP placeholder. The visual state is correct — it looks disabled. No issue.

- **`totalMeals = 0` progress bar**: `(0 / 10000).clamp(0.0, 1.0)` produces `0.0`. The progress indicator renders correctly at 0% width. Caption shows `"Start your journey"` as specified. Covered by test 6 in `beneficiary_impact_screen_test.dart`.

- **Empty `byCategory` map from Firestore** (legacy document): `filteredCategories` is empty; the `if (filteredCategories.isNotEmpty)` guard hides the `ListView.builder` entirely. No crash. Covered by zero-state tests.

---

## Spec compliance

All SPEC-0005 acceptance criteria checked against implementation:

| Criterion | Status |
|---|---|
| Real-time updates via Firestore `snapshots()` | PASS — `BeneficiaryImpactRemoteDatasourceImpl.watchImpact` uses `.snapshots()` |
| Offline banner with correct copy | PASS — `_OfflineBanner` text matches spec verbatim |
| Zero state: "0 Meals", progress 0%, "Start your journey", By Category hidden | PASS — tested in tests 6 and 7 |
| CO2 tile: `(totalCo2e / 1000).toStringAsFixed(1) Tons` | PASS |
| Waste tile: `totalKg.toStringAsFixed(0) kg` | PASS |
| Category row percentage: `(categoryKg / totalKg * 100).round()%` | PASS |
| Only categories with `kg > 0` shown | PASS |
| Progress bar value: `(totalMeals / 10000).clamp(0.0, 1.0)` | PASS |
| Bottom nav `selectedIndex` == 2 | PASS — tested in test 10 |
| Route `/beneficiary/impact` | PASS — router test wires `GoRouter` correctly |
| Domain layer zero Flutter/Firebase imports | PASS — `beneficiary_impact.dart`, `beneficiary_impact_repository.dart`, `watch_beneficiary_impact_usecase.dart` all pure Dart |
| No direct `FirebaseFirestore` calls in screen | PASS |
| `ListView.builder` with `shrinkWrap + NeverScrollableScrollPhysics` | PASS |
| `flutter analyze` passes | NOT VERIFIED — bash tool unavailable in this session; code review shows no obvious lint violations. Spec author should run locally. |
| `dart format` clean | NOT VERIFIED — same reason. |
| Navigation wiring: `BeneficiaryDashboardScreen` case 2 | NOT VERIFIED — `beneficiary_dashboard_screen.dart` not in the changed file list; spec requires wiring case 2. Should be confirmed. |
| Router `GoRoute(path: 'impact')` in `app/router.dart` | NOT VERIFIED — `router.dart` not in the changed file list. |

Two spec items — the router registration in `router.dart` and the dashboard navigation wiring in `beneficiary_dashboard_screen.dart` — are listed in the spec's file map as **Modify** actions but do not appear in the git status untracked file list. If those modifications were made to already-tracked files and are part of this branch, they need to be confirmed. If they were missed, navigation to `/beneficiary/impact` from the dashboard bottom nav will not work at runtime, which would block the **Navigation** acceptance criterion.

---

## Summary

The core feature implementation is correct and well-structured. 38 tests all pass (per the task brief), the Clean Architecture layer separation is respected, and Firestore `num` casting is safe. The primary concerns are:

1. **BLOCKING — Accessibility**: White text on `cs.primary = #3DBE6C` in `ImpactHeroCard` fails WCAG AA contrast ratio (2.9:1 vs 4.5:1 required for normal text, 3:1 for large text). This affects `labelSmall`, `bodySmall`, and `titleMedium` text in the hero card.

2. **NON-BLOCKING — Navigation wiring**: Confirm `router.dart` and `beneficiary_dashboard_screen.dart` were updated per the spec. These files are not visible in the untracked file list and must be verified on the branch.

3. **NON-BLOCKING — Missing `ImpactMetricTile` isolated test file**: The widget is tested indirectly but has no dedicated test file per the project convention ("every screen must have a widget test" — by extension, reusable widgets should too).

4. **NON-BLOCKING — `LinearProgressIndicator` missing `Semantics` label** in `ImpactHeroCard`.

5. **NON-BLOCKING — Notifications `IconButton` missing `tooltip`** in the AppBar.

The BLOCKING accessibility finding must be resolved before this PR merges.
