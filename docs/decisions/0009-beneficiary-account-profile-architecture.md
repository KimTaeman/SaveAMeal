# 0009 — Beneficiary account & profile: mirror donor pattern, reuse existing Firestore collections

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-03

## Problem

The beneficiary shell has a broken Account tab: tapping index 3 on `BeneficiaryHomeScreen` calls `context.go('/beneficiary/account')`, which has no matching `GoRoute`, causing a silent navigation failure visible to every beneficiary on every launch. Fixing it requires adding a full account layer (domain entity, repository interface, use cases, data implementation, and three screens). A structural decision was needed on how to organise those files and which Firestore data paths to use.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Mirror donor account pattern — all new files inside `features/beneficiary/` | Zero new patterns; uses already-reviewed data flow; feature isolation preserved; no new collections or packages | `FirestoreService` gains two new methods; two Firestore reads per profile load; composite index required for delivery history query |
| 2 | Shared generic account module under `lib/shared/` or `lib/features/account/` | Single implementation for `users/{uid}` reads/writes; reusable if more roles are added | Donor and beneficiary org profiles are structurally different — shared screen becomes conditional-heavy; routing must push role logic into `shared/`; higher design cost for an abstraction with only two current consumers |
| 3 | Lift `users/{uid}` CRUD into `lib/features/users/`; keep org profile role-specific | Personal info written once; `UserProfile` entity in a neutral module | Requires moving a working donor screen, creating regression risk; changes `router.dart` for a non-beneficiary concern; this is a standalone refactor that should not be bundled with a P1 bug fix |

## Decision

**Chosen:** Option 1 — mirror the donor account pattern inside `features/beneficiary/`, reading from existing `users/{uid}` and `beneficiaries/{uid}` Firestore collections.

This resolves the P1 broken tab with the smallest change surface: no new abstractions, no new collections, and no new third-party packages. Every new file stays inside `features/beneficiary/`, making the PR reviewable in isolation without touching the donor shell. If a third role requires an account tab in future, extracting a shared module at that point will have two concrete templates rather than requiring upfront speculation.

## Reversal Cost

Medium — reversing to Option 2 or 3 requires extracting `BeneficiaryProfile`, `BeneficiaryAccountRepository`, and the three screens out of `features/beneficiary/` into a shared module, updating all import paths and provider wiring, and regression-testing the donor shell. Scope grows with every additional screen built against the mirrored pattern.

## Consequences

Easier: the flutter-engineer can follow the donor account implementation line-for-line; reviewers can audit all changes within a single feature directory; no Firestore rules or schema changes are required.

Harder: any new user-facing field must be added in both `BeneficiaryProfile` (domain entity) and `BeneficiaryModel` (Freezed data model), plus the mapper in `BeneficiaryAccountRepositoryImpl`; the delivery history query requires a composite Firestore index on `(beneficiaryId ASC, status ASC)` that must be provisioned before the feature is live in production.
