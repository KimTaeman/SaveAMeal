# 0008 — Domain entities must be plain Dart; shared Freezed models must not cross the domain boundary

**Status:** ACCEPTED
**Author:** Architect agent
**Date:** 2026-06-03

## Problem

The `donor-account-screens` PR introduced `DonorAccountRepository` whose interface references `UserModel` from `core/models/user_model.dart`. `UserModel` is a `@freezed` class annotated with `json_serializable`, making it dependent on `freezed_annotation` and `json_annotation` for code generation. All other domain entities in the codebase (`AppUser`, `Batch`, `BatchItem`, `DonorMetrics`, `Beneficiary`) are plain Dart classes with zero annotations. Allowing a Freezed model to appear in a domain interface creates an inconsistent rule, couples the domain's stability to serialization decisions, and allows JSON field names to leak into domain types.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Allow `UserModel` directly in domain interfaces | No extra files; fast to implement | Domain purity is violated; swapping serialization format touches domain; JSON key names can leak into domain API |
| 2 | Introduce a plain Dart `DonorProfile` entity in domain; `UserModel` stays in `data/` | Consistent with all existing entities; domain is backend-agnostic; data layer owns serialization entirely | Additional mapper in `DonorAccountRepositoryImpl`; two types to keep in sync when fields are added |
| 3 | Move all entities to Freezed across the board (domain included) | Reduces mapper code; single source of truth per type | Makes `freezed_annotation` a transitive dependency of the domain layer; domain is no longer portable to non-Flutter Dart projects; violates the project's stated constraint |

## Decision

**Chosen:** Option 2 — introduce plain Dart domain entities; keep Freezed models in `data/`

Freezed and `json_serializable` are serialization concerns that belong in the data layer. Every existing domain entity in this project is a plain Dart class and that consistency must be maintained. The cost of a one-file mapper per feature is low and pays for itself in the ability to change Firestore field names or swap the backend without touching domain or presentation code.

## Reversal Cost

Medium — changing this decision would require converting plain domain entities to Freezed across all features, adding `freezed_annotation` to domain-facing packages, and updating all mapper sites. The scope grows proportionally with the number of features.

## Consequences

Easier: domain entities can be shared in a pure-Dart package with no Flutter or annotation dependencies; JSON schema evolution does not affect domain or presentation code; the domain is testable without any codegen step.

Harder: each new user-facing field must be added in two places (the domain entity and the Freezed model) and the mapper in the repository impl must be updated; reviewers must enforce this split at PR time.
