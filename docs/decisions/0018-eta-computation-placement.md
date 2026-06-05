# 0018 — ETA computation and write-path placement

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-05

## Problem

The `feat/beneficiary-batches` PR introduces live ETA streaming: every 30 seconds,
`DriverNotifier` computes travel-time minutes (via `etaMinutes()` in `core/utils/`) and
calls `_repo.updateBatchEta()`. The integer-minute throttle check (`if (newEta ==
_lastEtaMinutes) return`) and the repository write are both performed inside a private
method on the notifier — a Presentation-layer class. Every other write-path in the driver
feature is wrapped in a use-case class in `domain/usecases/`. ADR-0013 permits bypassing
use cases only for read-only passthrough streams. The question is where the ETA computation
and throttle logic should live.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Keep ETA logic in `DriverNotifier` (status quo in this PR) | Fewer files; logic is co-located with the timer that triggers it | Write path with business logic (throttle, Haversine call) lives in Presentation; cannot be unit-tested without a Riverpod harness; violates ADR-0013 policy for write paths |
| 2 | Extract to `UpdateBatchEtaUsecase` in `domain/usecases/`; use case imports `core/utils/distance_utils.dart` (pure Dart) | Write path is testable at the domain boundary without Flutter; consistent with all other driver write-path use cases; `distance_utils.dart` import moves out of Presentation | One additional file; use case must communicate the computed ETA back to the notifier so `_lastEtaMinutes` can be updated (return value or out-param) |
| 3 | Move `etaMinutes()` into the use case body rather than importing `distance_utils.dart` | Use case is fully self-contained | Duplicates Haversine logic; `distance_utils.dart` exists precisely to avoid this; `haversineKm` is also used in other potential contexts |

## Decision

**Chosen:** Option 2 — `UpdateBatchEtaUsecase` in `domain/usecases/`.

The use case imports `core/utils/distance_utils.dart` (pure Dart, zero Flutter or Firebase
imports) and `DriverRepository`. It accepts driver and destination coordinates plus the last
known ETA, returns the newly computed ETA (or null if unchanged), and the repository write
occurs inside the use case. `DriverNotifier._writeEtaIfChanged` becomes a two-line call
site that updates `_lastEtaMinutes` from the return value. This is consistent with
`ClaimBatchUsecase`, `ConfirmPickupUsecase`, and `ConfirmDeliveryUsecase`, which all follow
the same pattern.

## Reversal Cost

Low — if the team decides to inline the logic back into the notifier, the use-case file is
deleted and three lines are added to `driver_notifier.dart`. No schema or API changes.

## Consequences

Easier: ETA throttle logic and the Haversine call are unit-testable with a mocked
`DriverRepository`; no Riverpod or platform harness required. The Presentation layer no
longer imports `core/utils/distance_utils.dart` directly.

Harder: the notifier must receive the use case via `ref.read` at `build()` time (same
pattern as `_repo`); the use case must return enough information for the caller to update
`_lastEtaMinutes`.
