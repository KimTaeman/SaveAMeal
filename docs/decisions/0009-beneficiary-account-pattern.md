# 0009 — Beneficiary Account Feature: Mirror Donor Pattern vs. Shared Module

**Status:** PROPOSED
**Author:** architect
**Date:** 2026-06-03

## Problem

The beneficiary shell has a broken Account tab (index 3 on the `NavigationBar`). Implementing the missing account screens requires choosing how the data layer and UI are structured: replicate the existing donor account pattern inside `features/beneficiary/`, extract a shared generic account module, or refactor personal-info concerns into a shared `users/` feature first.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Mirror donor pattern inside `features/beneficiary/` | No new abstractions; zero cross-feature risk; reviewable in isolation; reuses `UserProfileUpdate` and `UpdateUserUsecase` shape already accepted in review | Two-document profile load; near-duplicate of donor account layer |
| 2 | Shared generic account module under `lib/shared/` or `lib/features/account/` | Eliminates duplication if a third role adds an account tab | Structural divergence between donor org profile and beneficiary org profile makes a generic screen conditional-heavy; cross-role blast radius; higher design cost |
| 3 | Lift personal info into `lib/features/users/`; keep org profile role-specific | `users/{uid}` logic written once; role-neutral domain entity | Requires refactoring the working `PersonalInformationScreen` from the donor path; donor regression risk; bundles a refactor with a P1 bug fix |

## Decision

**Chosen:** Option 1 — Mirror donor pattern inside `features/beneficiary/`.

The donor account feature (`donor_account_provider.dart`, `DonorAccountScreen`, `PersonalInformationScreen`, `OrganizationProfileScreen`) has already been reviewed and accepted. Mirroring its structure for beneficiaries introduces no new patterns, keeps every new file inside `features/beneficiary/` for isolated review, and resolves the P1 broken tab with the smallest change surface. The structural differences between donor and beneficiary org profiles (surplus types / operating hours vs. org type / mission statement) mean a generic shared screen would require role-discriminating conditionals, which is the type of coupling Clean Architecture is designed to avoid. If a third role requires an account tab, two concrete templates will exist to guide the abstraction at that point.

## Reversal Cost

Medium — if the team later extracts a shared account module, the `BeneficiaryAccountRepository`, `BeneficiaryProfile` entity, and account screens written under this decision become the starting point for that extraction. The domain interfaces are stable; only the presentation layer would need restructuring. No Firestore schema changes are required to reverse.

## Consequences

**Easier:**
- Flutter engineer can implement the feature without waiting for a shared-module design decision.
- Reviewer can audit all new code in `features/beneficiary/` without touching `features/donor/`.
- `BeneficiaryRepository` stub (`// TODO`) is paid down as a side-effect.

**Harder:**
- If a third role (e.g. volunteer/driver) adds an account tab, three near-identical account layers will exist before extraction pressure forces the shared module.
- `FirestoreService` grows two new methods (`getBeneficiary`, `updateBeneficiary`), slightly widening the service interface.
