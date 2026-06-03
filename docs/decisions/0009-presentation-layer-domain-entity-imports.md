# 0009 — Presentation layer may import domain entities directly

**Status:** ACCEPTED  
**Author:** architect  
**Date:** 2026-06-03

## Problem

The `DonorImpactScreen` PR raised the question of whether a presentation-layer widget (screen, widget, or provider) is permitted to import and use domain entities (e.g., `Batch`, `DonorMetrics`, `FoodCategory`) and domain enums directly. The alternative would be to have the presentation layer work exclusively through view-models or DTOs that the provider layer produces, never touching domain types directly.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Presentation imports domain entities and enums directly | No redundant mapping layer; domain types are already pure Dart and safe to use in widgets; aligns with how Riverpod providers expose domain types via `AsyncValue<DomainType>` | If domain entities grow framework imports (violation of domain purity), the presentation layer silently inherits them |
| 2 | Presentation uses dedicated view-model classes; providers map domain → view-model | Complete decoupling; view-models can be optimised for display (pre-formatted strings, merged fields) | Significant boilerplate for read-only screens; two parallel type hierarchies to maintain; providers must be changed to map before expose |
| 3 | Presentation imports domain entities but never switches on enums; string conversion lives in a shared `formatters/` layer | Keeps switch logic out of widgets; formatter can be unit-tested independently | Additional indirection for simple mappings; risk of the formatter becoming a dumping ground |

## Decision

**Chosen:** Option 1 — presentation layer may import domain entities and enums directly.

Domain entities in this project are pure Dart with zero framework imports, making them safe to use at any layer above Domain. Riverpod providers already expose `AsyncValue<DomainType>` directly — adding a mandatory view-model mapping layer would require every provider to maintain a parallel output type with no architectural benefit for read-only display screens. Option 3 is a reasonable evolution if enum-switching logic becomes widespread or needs independent testing; it should be adopted when more than three screens perform non-trivial enum formatting.

**Constraint added by this decision:** any switch statement on a domain enum that lives inside a presentation-layer widget must be exhaustive (no `default` arm that silently swallows unknown cases). Lint rule `exhaustive_cases` must be enabled to enforce this.

## Reversal Cost

Medium — if the team later decides to mandate view-models, every provider and every screen that currently exposes or consumes a domain entity must be updated. The refactor is mechanical but touches a large surface area.

## Consequences

Easier:
- Screens can be written directly against domain types with no extra mapping step.
- Provider signatures stay concise (`Stream<DonorMetrics>` rather than `Stream<DonorMetricsViewModel>`).

Harder:
- Domain entity changes (field renames, type changes) will cause compile errors in presentation files directly, requiring coordinated updates.
- Enum switches in presentation code must be kept exhaustive; incomplete mappings (as found in `_categoryLabel` in the donor-impact-screen PR) will produce wrong UI silently unless the `exhaustive_cases` lint is active.
