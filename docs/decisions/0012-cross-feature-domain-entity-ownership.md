# 0012 — Cross-feature domain entity ownership: no domain-to-domain imports between features

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-04

## Problem

During the `feat/beneficiary-profile` review, the beneficiary domain repository interface (`beneficiary_account_repository.dart`) and its use case (`update_personal_info_usecase.dart`) were found importing `UserProfileUpdate` from `lib/features/donor/domain/entities/`. This creates a compile-time dependency from the beneficiary domain onto the donor domain: a change to `UserProfileUpdate` can silently break the beneficiary feature. It also leaks donor-specific fields (`orgName`, `managerName`, `bannerUrl`, `surplusTypes`) into a context where they are irrelevant. The architecture rules (CLAUDE.md) require the domain layer to be pure Dart with zero framework imports, but do not explicitly address cross-feature domain imports. This ADR makes the rule explicit and documents the remediation pattern.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Keep shared `UserProfileUpdate` in `donor` domain; both features import from there | One class, no duplication | Creates a hard coupling between unrelated features; donor refactors break beneficiary; donor-specific fields pollute the beneficiary update contract |
| 2 | Move `UserProfileUpdate` to `lib/shared/domain/` | Neutral ownership; both features can import without cross-feature dependency | `shared/domain/` is a new module pattern not yet used; class must remain broad enough for both donors and beneficiaries, reintroducing the field-bloat problem |
| 3 | Create a separate `BeneficiaryPersonalInfoUpdate` entity in `lib/features/beneficiary/domain/entities/` (chosen) | Zero cross-feature coupling; entity shape matches exactly what the beneficiary form writes; donor domain is untouched | Slight duplication of four shared fields (`name`, `phone`, `location`, `photoUrl`); two update classes must be maintained if shared fields change |

## Decision

**Chosen:** Option 3 — each feature owns its own update value objects. The beneficiary feature introduces `BeneficiaryPersonalInfoUpdate` in `lib/features/beneficiary/domain/entities/` containing only the fields that `updatePersonalInfo` actually writes for a beneficiary (`name`, `phone`, `location`, `photoUrl`). `UserProfileUpdate` remains owned by the donor domain and is never imported outside `features/donor/`.

Domain features are bounded contexts. Coupling one feature's domain layer to another's creates a hidden dependency graph that the Clean Architecture boundary is specifically designed to prevent. The field sets for personal info updates are already diverging (donors have `bannerUrl`, `surplusTypes`, `operatingHours`; beneficiaries do not), so the duplication is not true duplication — it is intentional divergence. Four shared field names do not justify a cross-feature import.

## Reversal Cost

Low — the beneficiary `BeneficiaryPersonalInfoUpdate` entity is used in exactly three files (repository interface, use case, presentation screen). Switching to a shared module later requires creating `lib/shared/domain/personal_info_update.dart`, updating those three import paths, and removing the feature-local entity file. No behavior changes.

## Consequences

**Easier:** Each feature's domain layer can evolve independently. Refactoring `UserProfileUpdate` in the donor feature has no effect on the beneficiary feature. The beneficiary update contract is minimal and self-documenting.

**Harder:** If a truly shared personal-info field is added in future (e.g., `preferredLanguage`), it must be added to both update classes. A lint rule or CI check should be added to detect `import 'package:saveameal/features/<A>/domain/` inside `features/<B>/domain/` to catch future violations automatically.
