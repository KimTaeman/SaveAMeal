# 0010 — Cross-feature domain enum sharing: FoodCategory

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-03

## Problem

`BeneficiaryImpact` (beneficiary domain entity) uses `FoodCategory` as the key type of its `byCategory: Map<FoodCategory, double>` field. `FoodCategory` currently lives in `features/donor/domain/entities/food_category.dart`. This means the beneficiary domain layer has a compile-time import dependency on the donor feature's domain layer, creating horizontal coupling between two sibling feature domains. The team must decide whether to allow this import to stand, move the enum to a shared location, or duplicate it.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | **Leave the cross-feature import as-is** (current state) | Zero migration cost; `FoodCategory` is a pure-Dart enum with no imports, so domain purity is not broken today | Donor domain changes silently break the beneficiary domain; the rule "features are independent" is violated; a third feature needing `FoodCategory` (e.g., driver, analytics) must also import from donor |
| 2 | **Move `FoodCategory` to `lib/shared/domain/enums/food_category.dart`** | Single canonical source; no feature domain depends on another; third features import from shared without coupling to donor | One file-move plus import updates across all files that reference `FoodCategory` (donor entities, data models, beneficiary entity, presentation widgets) |
| 3 | **Duplicate `FoodCategory` per feature** | Zero coupling | Two enums must be kept in sync; `FoodCategory` values from one feature cannot be compared to those from another without conversion; worse than option 1 |

## Decision

**Chosen:** Option 1 for MVP, with a scheduled migration to Option 2.

`FoodCategory` is currently a single-line pure-Dart enum with no imports. The coupling risk is real but low for MVP because the enum is stable (six fixed values that mirror the Firestore schema). The beneficiary-impact-screen PR carries an explicit code-level TODO acknowledging this debt. Option 2 is the correct long-term position; it must be executed before any third feature domain imports `FoodCategory`, and must be tracked as a backlog item. Option 3 is rejected unconditionally.

## Reversal Cost

**Low.** Option 2 migration requires moving one file and updating imports in approximately eight files (two domain entities, three data models, three presentation widgets). No behavior changes, only path changes. The migration is safe to do at any time as a pure refactor.

## Consequences

**Easier:** No migration work required now; beneficiary impact screen ships without ceremony.

**Harder:** Any rename or structural change to `features/donor/domain/entities/food_category.dart` breaks the beneficiary domain silently (only caught by `flutter analyze`); the rule "feature domains are independent" has a documented exception until Option 2 is executed; reviewers must block PRs that add a third cross-feature import of `FoodCategory` without first migrating to `shared/domain/`.
