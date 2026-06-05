# 0017 — IntakeStatus enum extension for delivered and closed states

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-04

## Problem

The `IntakeStatus` enum previously contained four values (`pending`, `dispatched`, `collected`, `cancelled`) that did not have a 1-to-1 correspondence with the Firestore `status` strings `delivered` and `closed`. The mapper silently coerced both strings into `collected`. SPEC-0008 requires the presentation layer to distinguish `delivered` (CTA visible) from `closed` (banner visible), which requires distinct enum values. The decision is whether to add new values to the existing enum or introduce a separate domain type.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Add `open`, `delivered`, `closed` to `IntakeStatus`; retain `collected` and `pending` as legacy values | Preserves backward compatibility with existing test fixtures that use `pending`; mapper wildcard arm catches unknown strings safely | Enum grows stale values (`collected`, `pending` as fallback) that are never the primary target of any Firestore string; risks confusion |
| 2 | Replace enum entirely with a clean set matching Firestore strings exactly (`open`, `claimed`, `pickedUp`, `delivered`, `closed`, `cancelled`) | Perfect 1-to-1 mapping; no dead values | Breaking change to every consumer of the enum; larger blast radius |
| 3 | Introduce a separate `DeliveryStatus` enum for the detail view only | Isolation of the new distinction | Duplication; two enums for the same lifecycle concept |

## Decision

**Chosen: Option 1 — additive extension of the existing enum.**

Adding `open`, `delivered`, and `closed` while retaining `collected` and `pending` is a non-breaking change that allows the mapper to route Firestore strings to accurate domain values without touching any existing consumer. The `collected` value becomes an orphan (no Firestore string routes to it after the mapper fix) but it can be removed in a follow-up cleanup ADR without urgency. The wildcard arm `_ => IntakeStatus.pending` acts as a safe fallback for unknown strings.

## Reversal Cost

Low. Removing the new values would require reverting the mapper and the two `delivery_detail_screen.dart` conditionals. No Firestore schema change is needed.

## Consequences

**Easier:** `DeliveryDetailScreen` can pattern-match exactly on `delivered` and `closed` without ambiguity. Mapper coverage is now complete for all known Firestore status strings.

**Harder:** The `collected` and `pending` enum values are now dead code and may cause confusion for future engineers. A follow-up task should audit all uses of `collected` and `pending` and either re-purpose or remove them. Any exhaustive switch expression on `IntakeStatus` must now handle seven arms instead of four.
