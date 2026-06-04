# Session: 2026-06-03 — beneficiary-impact-screen

**Date:** 2026-06-03
**Member:** khinnadiko
**Agent:** flutter-engineer
**Task:** Implement the Beneficiary Impact Screen per SPEC-0005

---

## Context

PROP-0005 (ACCEPTED) and SPEC-0005 (DRAFT, pending approval) define this feature.
Stub files have been scaffolded — the engineer's job is to fill them in.

Relevant prior art in the codebase:
- `DonorDashboardScreen` + `DonorMetrics` — same Riverpod stream pattern this feature mirrors.
- `BeneficiaryHomeScreen` — the app bar, offline banner, and bottom nav pattern to replicate.
- `donor_provider.dart` — the datasource → repository → usecase → StreamProvider chain to follow.

## Plan

1. [ ] Run `dart run build_runner build --delete-conflicting-outputs` to generate
       `beneficiary_impact_provider.g.dart` from the new `@riverpod` providers.
2. [ ] Implement `BeneficiaryImpactScreen` per the screen layout spec in SPEC-0005.
3. [ ] Implement `ImpactHeroCard` — green hero card, meal count, LinearProgressIndicator,
       yearly-goal caption, zero/"Start your journey" empty state.
4. [ ] Implement `ImpactMetricTile` — CO2 Diverted and Waste Saved cards.
5. [ ] Implement `ImpactCategoryRow` — icon + category name + percentage ListTile.
6. [ ] Wire `/beneficiary/impact` sub-route in `apps/mobile/lib/app/router.dart`.
7. [ ] Wire `case 2: context.go('/beneficiary/impact')` in `BeneficiaryHomeScreen`'s
       `NavigationBar.onDestinationSelected`.
8. [ ] Amend `functions/src/computations.ts` — add `category?: string` to `BatchItem`,
       add `computeByCategory()` function.
9. [ ] Amend `functions/src/onDeliveryComplete.ts` — add the two-op beneficiary write
       (set for scalar counters + update with dot-notation keys for byCategory).
10. [ ] Write widget tests per the test plan in SPEC-0005.
11. [ ] Run `flutter analyze` and `dart format .` — must pass clean.

## Decisions Made

- `FoodCategory` is imported from `package:saveameal/features/donor/domain/entities/food_category.dart`
  rather than the beneficiary domain path stated in the spec, because the type currently lives in
  the donor feature. The spec import path was aspirational. Moving `FoodCategory` to `shared/` is
  deferred post-MVP.
- `byCategory` dot-notation Cloud Function update requires two ops (set + update) because
  `FieldValue.increment` does not work for nested map keys inside `set({merge: true})`.

## Blockers / Open Questions

- `firestoreServiceProvider` is assumed to return `FirebaseFirestore` — verify against
  `apps/mobile/lib/services/service_providers.dart` before running build_runner.
- The Cloud Function deployment must be done by the user (confirmed in spec open questions).

## Handoff

After implementation, hand to **qa-engineer** for review against SPEC-0005 acceptance criteria.
The QA sweep should cover: real-time update timing, offline cached-value display, zero state,
category row filtering, and bottom nav `selectedIndex: 2`.

**Review needed from:** qa-engineer
