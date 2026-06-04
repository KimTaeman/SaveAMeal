# 0010 — Driver Profile Entity Strategy

**Status:** PROPOSED
**Author:** architect
**Date:** 2026-06-03

## Problem

The driver feature needs a profile screen (PROP-0005). Three structurally different approaches exist for modelling driver identity: reuse the existing `UserModel` god object, introduce a dedicated `DriverProfile` domain entity mirroring the donor pattern, or ship a read-only view with no domain additions. The choice determines domain cleanliness, long-term maintainability across roles, and offline caching scope.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Extend `UserModel` with driver fields + shared profile screen | One model; minimal boilerplate | `UserModel` becomes a wider god object; conditional rendering across roles creates a maintenance trap; Freezed codegen regenerated for all role changes |
| 2 | Dedicated `DriverProfile` entity + feature-scoped screen | Clean domain; mirrors proven donor pattern; isolated to driver feature; Hive cache scoped per role | More boilerplate; potential future refactor if profile management is unified across roles |
| 3 | View-only profile, edits via admin | Minimal implementation effort | Does not meet user requirements; operational admin overhead; no avatar upload; stale data accumulates silently |

## Decision

**Chosen:** Option 2 — Dedicated `DriverProfile` domain entity + feature-scoped screen

`UserModel` already carries fields exclusive to donors (`orgName`, `surplusTypes`, `operatingHours`, `bannerUrl`) and beneficiaries (`managerName`, `status`); adding driver-specific fields (`vehicleType`, `licensePlate`, `emergencyContact`) would make it unmanageable and violate single-responsibility at the domain level. The `DonorProfile` pattern is already proven in the codebase, giving the Flutter engineer a concrete template that reduces implementation risk. A feature-scoped `DriverProfileRepository` interface keeps the domain layer dependency-free and the data-layer Firestore implementation isolated, consistent with the project's Clean Architecture constraint.

## Reversal Cost

**Medium.** If the team later decides to unify profile management into a shared cross-role entity, the `DriverProfile` entity and its repository interface must be merged or replaced, and the Hive adapter for driver profile data will need migration. This is a deliberate future refactor, not an accident — the boundary is explicit and documented.

## Consequences

**Easier:** Domain stays clean per role; donor and driver profile screens can evolve independently; Hive cache for driver profile is scoped and does not touch donor or beneficiary data; widget tests for driver account screen are isolated.

**Harder:** Any feature that needs to display a unified "any-role profile" view (e.g. an admin dashboard) must aggregate across multiple entities; a future profile-unification refactor touches more files than Option 1 would have required upfront.
