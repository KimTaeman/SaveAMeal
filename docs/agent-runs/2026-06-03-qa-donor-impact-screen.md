# QA Review — 2026-06-03 — donor-impact-screen

**Reviewer:** qa-engineer
**Session ID:** donor-impact-screen
**PR / Branch:** feature/donor-impact-screen
**Date:** 2026-06-03

---

## Summary

Reviewed `DonorImpactScreen` (`apps/mobile/lib/features/donor/presentation/screens/donor_impact_screen.dart`) and its widget test file (`apps/mobile/test/widget/features/donor/donor_impact_screen_test.dart`). The screen itself is well-formed: it satisfies the no-unbounded-ListView rule, has a tooltip on the bell, uses no remote images, and produces real-time data via Stream-backed providers. However, one test (Test 6 — "No donations yet") will fail against the current screen because the empty-state branch was removed. Four additional test gaps were identified: no bell navigation test, no category percentage test with non-empty batches, no CO2/kg stat value assertion, and no test for the hardcoded progress bar and "0% of yearly goal" label. No golden tests exist for the screen. Verdict: CHANGES REQUESTED.

---

## Findings

| # | Severity | Area | Description | Fix |
|---|----------|------|-------------|-----|
| 1 | **Critical — blocks merge** | Test/Screen mismatch | Test 6 (`shows No donations yet when batch list is empty`) asserts `find.text('No donations yet')` but the screen has been updated to always render the 4 fixed category rows. There is no `'No donations yet'` string anywhere in the screen source. This test will fail on every CI run. | Either restore the empty-state branch in the screen (show `'No donations yet'` when `batches.isEmpty && categoryTotal == 0`) or replace Test 6 with a test that asserts all 4 fixed category rows render with `0%` when the batch list is empty. The regression-test rule requires the fix ship with a test that reflects the correct current behaviour. |
| 2 | **High** | Coverage — missing test | There is no test for bell icon navigation to `/notifications`. The test file registers the `/notifications` stub route in `_buildRouter()`, so the infrastructure is present, but no test taps the bell and asserts the destination. A missed navigation regression has no safety net. | Add `testWidgets('taps bell navigates to Notifications screen', ...)` that taps `find.byIcon(Icons.notifications_outlined)` and expects `find.text('Notifications Screen')` after `pumpAndSettle`. |
| 3 | **High** | Coverage — missing test | No test verifies category percentage calculation with a non-empty batch list. All 7 tests supply `Stream.value(<Batch>[])` for `activeBatchesProvider`. The `_buildCategoryMap` / percentage logic is completely untested. A wrong formula would pass all current tests. | Add a test that provides at least two batches with mixed `FoodCategory` values and asserts the rendered `%` string matches the expected calculation. |
| 4 | **Medium** | Coverage — shallow tests | Tests 1–5 and 7 only assert text presence (`'SaveAMeal'`, `'TOTAL IMPACT'`, `'Meals'`, `DonorBottomNav` type, `'By Category'`, `'2480'`). No test asserts CO2e or kg values from `_testMetrics` (372.0 / 1240.0), nor verifies `'0% of yearly goal'` or `'0.0'` format via `toStringAsFixed(1)`. Shallow coverage means a formatting regression or wrong field wiring would go undetected. | Add assertions for `find.text('372.0')`, `find.text('1240.0')`, and `find.text('0% of yearly goal')` in the existing Test 7 or a new test. |
| 5 | **Medium** | Coverage — golden tests absent | No golden test exists for `DonorImpactScreen` at text scales 1.0 and 1.5. The project rule requires one golden per screen. | Add `goldens/donor_impact_screen_1x.png` and `goldens/donor_impact_screen_1_5x.png` generated with `MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(1.5)), ...)`. Fix locale to `en_US` and theme to `AppTheme.light()`. |
| 6 | **Low** | Accessibility — stat cards | `_StatCard` displays the numeric value and unit as plain `Text` widgets inside a `Column` inside a `Container`. There is no `Semantics` node merging value + unit into a single readable announcement (e.g. `"372.0 Tons"` or `"CO2 Diverted: 372.0 Tons"`). A screen reader will read label, value, and unit as three separate, context-free utterances. | Wrap the `Container` in `Semantics(label: '$label: $value $unit')` or merge the child tree with `MergeSemantics`. |
| 7 | **Low** | Accessibility — progress bar | `LinearProgressIndicator` for yearly goal has no semantic label. A screen reader announces only `"0%"` with no context. | Wrap in `Semantics(label: '0% of yearly goal progress')`. |
| 8 | **Low** | Screen — hardcoded progress | Progress bar value is hardcoded `0.0` and label is hardcoded `'0% of yearly goal'`. This is not connected to any provider. When yearly goal data becomes available this will be a silent display bug. | Track as a follow-up issue. Not a test blocker but should have a TODO comment in source. |
| 9 | **Informational** | Design tokens | `Color(0xFF006E2F)` appears 4 times in the screen (AppBar icon, category row icons, category percentage text, `_StatCard` border, icon, and value text). The same advisory was raised for the donor account screens. Centralising to `cs.primary` or an `AppColors` token eliminates future inconsistency. | Non-blocking for this PR; track as a follow-up. |

---

## Checklist

- [x] `flutter analyze` — passes per engineer's session log (pre-existing errors in `beneficiary_dashboard_screen.dart` are out of scope)
- [x] `dart format` — no diff reported in session log
- [x] Screen has widget tests — yes (7 tests present)
- [x] No unbounded `ListView` — `ListView.builder(itemCount: 1)` satisfies the rule
- [x] No remote images — no `Image.network` or `CachedNetworkImage` calls; all icons are `Icon` widgets
- [x] Bell `IconButton` has `tooltip: 'Notifications'` — CONFIRMED present on screen line 55
- [ ] Semantic labels on stat card values — MISSING (Finding 6)
- [ ] Semantic label on progress bar — MISSING (Finding 7)
- [ ] Bell navigation test — MISSING (Finding 2)
- [ ] Category percentage test with real batch data — MISSING (Finding 3)
- [ ] Golden tests at 1.0 and 1.5 text scale — MISSING (Finding 5)
- [x] Text contrast `Color(0xFF006E2F)` on white — approximately 8.6:1, passes WCAG AA (4.5:1 for normal, 3:1 for large)
- [ ] Test 6 assertion matches current screen — FAILS (Finding 1, Critical)

---

## Accessibility Findings

- `_StatCard` value + unit `Text` widgets → no merged `Semantics` → screen reader reads three disconnected strings → wrap container in `Semantics(label: '$label: $value $unit')`
- `LinearProgressIndicator` (yearly goal) → no semantic label → screen reader announces raw percentage with no context → wrap in `Semantics(label: '0% of yearly goal progress')`
- Bell `IconButton` → `tooltip: 'Notifications'` is present → PASS

## Performance Findings

- Top-level `ListView.builder(itemCount: 1)` → satisfies no-unbounded-ListView rule → PASS
- No remote images → no `CachedNetworkImage` concern → PASS
- Both `donorMetricsProvider` and `activeBatchesProvider` are Stream-backed → UI will auto-update in real-time → PASS

---

## Verdict

**CHANGES REQUESTED**

One critical blocker: Test 6 asserts `'No donations yet'` but the screen no longer renders that string — this test will fail on CI and must be fixed before merge. Two high-severity test gaps follow (bell navigation and category percentage with real data). All other findings are medium or below and may be addressed in a follow-up, but Finding 1 is a hard block.
