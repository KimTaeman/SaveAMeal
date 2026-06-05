# 0018 — BatchStatus canonical home in shared/domain

**Status:** PROPOSED
**Author:** architect
**Date:** 2026-06-05

## Problem

`BatchStatus` is a lifecycle enum that is semantically owned by the batch
aggregate — not by any single user role. It is currently defined in
`features/donor/domain/entities/batch.dart`. The services layer
(`firestore_service.dart`) and the core data layer (`batch_model.dart`) already
import it from that location. As driver and beneficiary domain layers mature,
they will need to branch on batch status, forcing them to import from a sibling
feature's domain — the cross-feature coupling pattern ADR-0012 exists to
prevent. The question is: where should `BatchStatus` live so it is accessible
to all layers without creating feature coupling?

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Keep in `features/donor/domain/entities/batch.dart` | No migration cost today | Driver and beneficiary domain layers must import from `donor` domain; services layer is already coupled to a feature domain; violates ADR-0012 as usage grows |
| 2 | Move to `lib/shared/domain/entities/batch_status.dart` | Matches `FoodCategory` precedent; feature-agnostic; correct place for cross-feature domain contracts | Small one-time migration of three import sites (`batch_model.dart`, `firestore_service.dart`, donor presentation screens) |
| 3 | Duplicate into each feature's domain | No cross-feature imports | Enum values diverge over time; mapping boilerplate at every boundary; clearly wrong |
| 4 | Move to `lib/core/models/` alongside `BatchModel` | Single source near existing data layer consumers | Mixes domain concept into data/model layer; domain layer would import from data layer — inverted direction |

## Decision

**Chosen:** Option 2 — `lib/shared/domain/entities/batch_status.dart`

The project already established `lib/shared/domain/entities/` as the home for
cross-feature pure-Dart domain contracts when `FoodCategory` was moved there.
`BatchStatus` satisfies the same criteria: it is a domain concept, it is pure
Dart, and it is needed by more than one feature role. Placing it there costs one
small migration today in exchange for eliminating a structural debt that would
compound with every new feature that touches batch lifecycle.

## Reversal Cost

Low — `BatchStatus` is currently imported in exactly three files outside of the
donor feature. Reverting to donor-domain placement is a three-line find-and-replace.
If driver and beneficiary domain layers have since adopted the shared location,
the reversal cost rises to Medium.

## Consequences

**Easier:**
- Driver and beneficiary domain entities can reference `BatchStatus` without
  cross-feature imports.
- `firestore_service.dart` no longer couples the services layer to a specific
  feature's domain.
- ADR-0012 cross-feature coupling rule is satisfied for all current consumers.

**Harder:**
- Contributors must know to look in `shared/domain/` for cross-feature enums,
  not in whichever feature first needed the type. This should be documented in
  `CLAUDE.md` under the Architecture section.
