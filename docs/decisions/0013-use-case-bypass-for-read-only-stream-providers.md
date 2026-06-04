# 0013 — Use-case bypass for read-only stream providers

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-04

## Problem

Two stream providers in `beneficiary_provider.dart` call `IntakeRepository` methods directly without a wrapping use-case class: `intakeRequest` and `recentDeliveries`. A third provider, `driverLocation`, goes a layer further and calls `FirestoreService` directly, bypassing both the repository and any use-case. Meanwhile, `intakeRequestDetail` correctly routes through `WatchIntakeRequestDetailUseCase`. The question is whether requiring a dedicated use-case wrapper for every provider is the right policy, or whether a documented exception is acceptable for passthrough read-only streams.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Require a use-case class for every provider, including passthrough streams | Uniform pattern; every provider is testable at the use-case boundary; future business logic (rate limiting, caching, filtering) has a natural home | Boilerplate for streams that contain zero logic beyond delegation; three classes per feature for a one-liner |
| 2 | Allow providers to call the repository directly for read-only streams with no business logic; require a use-case only when logic exists | Reduces boilerplate; providers already tested through Riverpod overrides; repository is still the domain-boundary entry point | Two patterns coexist in the same file; new engineers may default to the shorter form even when logic is needed |
| 3 | Allow providers to call `FirestoreService` directly for cross-feature reads (e.g., `driverLocation`) that have no feature-specific repository | Avoids creating a throwaway repository method for a service method that is already correct and tested elsewhere | Presentation layer imports a service-layer class, crossing two layer boundaries simultaneously |

## Decision

**Chosen:** Option 2 for repository-level bypasses; Option 3 is flagged as a WARNING (not blocking) for the `driverLocation` case.

For passthrough read-only streams with no business logic (`intakeRequest`, `recentDeliveries`), calling the repository directly from a provider is an acceptable deviation from full use-case wrapping. The repository interface remains the domain boundary and is still easily mockable via Riverpod provider overrides in widget tests. The `driverLocation` bypass of the repository entirely in favour of `FirestoreService` is a pre-existing pattern in this codebase and is not introduced by this PR; the team must decide whether to consolidate it into a cross-feature repository in a future spec. New providers added after this ADR must use a use-case wrapper when any transformation, authorization guard, or conditional routing exists in the call path.

## Reversal Cost

Low for the repository-bypass case — adding a use-case wrapper is a one-file addition plus a two-line provider change. Medium for the `driverLocation` / `FirestoreService` bypass — requires introducing a new repository interface and a datasource that wraps `FirestoreService`, then updating all providers that reference the service directly.

## Consequences

Easier: providers for pure read-through queries are concise and do not require a separate use-case file.

Harder: the codebase has two provider patterns in the same file; code reviewers must check whether new providers that bypass the use-case layer have a legitimate reason to do so. The `driverLocation` bypass means `FirestoreService` is a transitive import from `beneficiary_provider.dart` — a presentation file now depends on a service-layer class, weakening the layer boundary.
