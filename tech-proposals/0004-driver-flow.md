---
title: "0004: Driver flow — browse, claim, pickup, and deliver batches"
description: "Give drivers a map-based UI to find open batches, claim them, confirm pickup via QR scan, share live location, and mark delivery complete."
---

# PROP-0004: Driver flow — browse, claim, pickup, and deliver batches

**Status:** ACCEPTED
**Author:** Kim Taeman (architect)
**Date:** 2026-05-26
**Spec:** [SPEC-0004](../tech-specs/0004-driver-flow.md)
**Approved by:** Kim Taeman

---

## Problem

Donors can log surplus batches (SPEC-0003), but there is no mechanism for a driver to discover or act on them. The batch lifecycle is stuck at `open` indefinitely — there is no end-to-end path through the app.

## Proposed Solution

Implement the full driver experience as a single `DriverMapScreen` (map + bottom sheet). Drivers see open batches as map markers, claim one via a Firestore transaction, follow a stepper through pickup and delivery, and share live location every 30 s to `driverLocations/{uid}` so beneficiaries can track progress.

## Alternatives Considered

### A — Separate screens per lifecycle step (PickupScreen → DeliveryScreen)

Each phase gets its own GoRouter route. **Rejected:** the map disappears between screens, which is disorienting during active delivery. Navigation boilerplate adds complexity without UX benefit.

### B — Persistent map + wizard overlay (sheet animates forward per step)

Map always visible; bottom sheet slides content forward like a wizard. **Rejected:** sheet animation synchronized with map camera is fiddly to implement correctly within the project timeline.

## Open Questions

All resolved during brainstorming session (2026-05-26):

- `BatchQrScreen` displays a `qr_flutter`-generated QR containing `batchId`. ✓
- Driver sees donor address at Claimed step and beneficiary address at PickedUp step. ✓

## Acceptance Criteria

- Driver can see all `status == "open"` batches as map markers.
- Claiming a batch uses a Firestore transaction; concurrent claim shows "Batch already taken" snackbar.
- Driver location is written to `driverLocations/{uid}` every 30 s while a batch is active.
- Batch status progresses `open → claimed → picked_up → delivered` via driver actions.
- `PickupScreen` and `DeliveryScreen` stubs are removed.
- `BatchQrScreen` is fully implemented (QR display).
- Every new screen has a widget test.
