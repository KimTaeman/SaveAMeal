# Architect Review — 2026-06-03 — donor-impact-screen

**Reviewer:** architect  
**Session ID:** donor-impact-screen  
**PR / Branch:** feature/donor-impact-screen  
**Date:** 2026-06-03

---

## Summary

This PR introduces `DonorImpactScreen`, a read-only presentation widget that replaces the route placeholder for `/donor/impact`. It consumes two pre-existing stream providers (`donorMetricsProvider`, `activeBatchesProvider`) and adds no new domain, data, or provider files. The router change is surgical. The `beneficiary_dashboard_screen.dart` change is confirmed in-file cleanup — the current file on `main` is fully clean and functional (no orphaned code present), so that diff represents legitimate pre-existing technical debt removal.

Overall the PR is structurally sound. Two findings must be resolved before merge: hardcoded colors are a project-convention violation, and `_categoryLabel` contains a semantically incorrect mapping that will produce wrong data in production.

---

## Findings

| # | Severity | Layer | Description | Required Fix |
|---|----------|-------|-------------|--------------|
| 1 | **BLOCKING** | Presentation | `_categoryLabel` maps `FoodCategory.meat`, `FoodCategory.beverages`, and `FoodCategory.other` all to the string `'Prepared Meals'`. The category breakdown will silently miscount and suppress those three categories from their correct bins. Additionally `FoodCategory.meat` is almost certainly not "Prepared Meals" — this appears to be an incomplete mapping left over from a draft. | Add the missing enum arms with correct labels, or file a domain task to align `FoodCategory` values with the display categories, and add a `default` fallback that surfaces unmapped values visibly during development. |
| 2 | **CHANGES REQUESTED** | Presentation | Five instances of `const Color(0xFF006E2F)` and two of `const Color(0xFF22C55E)` are hardcoded directly in the widget tree and in `_StatCard`. Project convention (CLAUDE.md) requires all colors to come from `cs.*` (ColorScheme) or `ac.*` (AppColors extension). This will diverge from the design system when the theme is updated. | Replace all hardcoded color literals with the appropriate `AppColors` or `ColorScheme` token. Brand green should be registered as `ac.primary` or a named `AppColors` slot — confirm with the design system owner which token is correct. |
| 3 | **Advisory** | Presentation | `_buildCategoryMap` and `_categoryLabel` are instance methods on `ConsumerWidget` but neither uses `this`, `ref`, nor `context`. Declaring them as instance methods implies statefulness or instance coupling that does not exist. | Declare both as `static` methods (or top-level private functions in the same file). This is a low-impact maintainability concern and does not block merge on its own, but should be resolved in the same pass as finding #1. |
| 4 | **Advisory** | Presentation | `ListView.builder(itemCount: 1, ...)` wrapping a single `Column` is an unusual pattern. The declared intent appears to be lazy/scrollable layout, but `itemCount: 1` negates any lazy benefit and is semantically identical to `SingleChildScrollView` + `Padding`. The distinction matters because `ListView.builder` is a project requirement for dynamic lists; using it here for a single static item muddies that convention. | Replace with `SingleChildScrollView` + `Padding` to match the intent. If the scroll behavior of `ListView` is preferred for consistency with other screens, add a comment explaining the choice. |
| 5 | **Advisory** | Presentation / Domain | `LinearProgressIndicator(value: 0.0)` with label `'0% of yearly goal'` is fully hardcoded. There is no domain entity, use case, or provider for yearly goal tracking. This is acceptable for MVP, but the placeholder will confuse users if it ships without a visible `// TODO` referencing the tracking issue. | Add a `// TODO(#<issue>): wire yearly goal progress when GoalTrackingUsecase is implemented` comment at the progress bar site. File a backlog issue if one does not exist. |
| 6 | **Informational** | Presentation | `DonorImpactScreen` imports `AppBar` with `backgroundColor: Colors.white` (hardcoded) while `beneficiary_dashboard_screen.dart` uses `cs.surface` for the same slot. Minor inconsistency, lower priority than finding #2 but should be fixed in the same pass. | Replace `Colors.white` with `cs.surface`. |
| 7 | **Informational** | Presentation | No widget test exists for `DonorImpactScreen`. CLAUDE.md states "every screen must have a widget test." The PR adds a screen without a test. | Create `test/widget/donor/donor_impact_screen_test.dart` covering at least: (a) renders without throwing given mock providers, (b) displays `DonorMetrics.empty` state without overflow. |

---

## Checklist

- [x] Domain imports in presentation layer are entities and interfaces only — no data-layer or Firebase imports
- [x] No new domain entities, use cases, or repositories introduced without a spec
- [x] Existing providers consumed correctly through Riverpod `ref.watch`
- [x] `DonorMetrics.empty` fallback used — no null-unsafe access on async data
- [x] Router change is additive and backwards-compatible
- [x] `beneficiary_dashboard_screen.dart` change confirmed as cleanup, not functional removal
- [ ] All colors from `cs.*` or `ac.*` — FAILED (5+ hardcoded literals)
- [ ] `_categoryLabel` mapping is semantically correct — FAILED (3 enum values mis-mapped)
- [ ] Widget test exists for new screen — FAILED

---

## Detailed Notes

### Layer boundaries (Check 1 and 3 from brief)

Importing domain entities (`Batch`, `DonorMetrics`, `FoodCategory`) directly into a presentation-layer screen is **correct and expected** under this project's Clean Architecture. The presentation layer depends on Domain; it must be able to hold and display domain types. The screen does not import anything from `data/` — no DTOs, no repository implementations, no Firebase types. `donor_provider.dart` itself instantiates `DonorRemoteDatasourceImpl` and `DonorRepositoryImpl` directly (a known provider-layer pragmatism), but `DonorImpactScreen` is insulated from that — it only touches the generated stream provider. This is acceptable.

### `_buildCategoryMap` / `_categoryLabel` placement (Check 2)

The methods are not `static`. In Dart, a method on a `ConsumerWidget` subclass is called on the widget instance. Since `ConsumerWidget` is `@immutable`, this is not a runtime hazard — the widget has no mutable fields — but it misleads readers into thinking the methods depend on widget state. The fix is one keyword (`static`) per method. The more significant issue is the semantic correctness problem described in finding #1.

### No new use case for impact summary (Check 4)

The PR is correct not to add a new use case. "Get impact summary" is already covered by `GetDonorMetricsUsecase` (metrics) and `WatchActiveBatchesUsecase` (batches for category breakdown). A third use case that simply composes those two would be a thin wrapper with no independent business rule, which would violate the single-responsibility principle rather than enforce it. The screen performs the `_buildCategoryMap` aggregation itself; if this logic needs to be tested independently or reused, it should be extracted to a `static` helper (finding #3) or, if it grows, to a dedicated use case at that time.

### `beneficiary_dashboard_screen.dart` change (Check 7)

The current file on `main` (read above) is complete and functional. There are no syntax errors, no orphaned declarations, and no dangling references. The 32-line removal described in the PR diff removed content that was in conflict with the current state — the file is clean post-merge. The removal does not break any visible feature.

---

## Verdict

**CHANGES REQUESTED**

Finding #1 (incorrect `_categoryLabel` mapping) is BLOCKING — it will silently produce wrong category percentages in production. Finding #2 (hardcoded colors) violates a project-wide enforced convention and must be resolved before merge. All other findings are advisory and may be addressed in follow-up issues, but #1 and #2 must be fixed in this PR.
