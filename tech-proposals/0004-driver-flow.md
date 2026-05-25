---
title: "0004: Driver flow — browse, claim, pickup, and deliver batches"
description: "Give drivers a map-based UI to find open batches, claim them, confirm pickup via QR scan + safety checklist + photo, share live location, verify delivery, and see impact on completion."
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

Implement the full driver experience across 7 screens (per Figma `LIdE6qDQzKpV3L5bAbO24w`): map with food-category markers, job detail, en-route navigation, QR pickup verification, safety checklist + photo upload, delivery handover verification, and a completion screen showing impact and points earned. Live location is shared every 30 s during active delivery.

## Alternatives Considered

### A — Single screen with bottom-sheet stepper

All driver logic in `DriverMapScreen`; phases rendered as stepper inside a bottom sheet. **Rejected:** Figma specifies separate full screens per phase, which gives more breathing room for safety checklist and photo upload UX.

### B — List view instead of map for batch discovery

Scrollable card list of open batches sorted by distance. **Rejected:** Figma specifies map-first with food-category chip markers as the primary browse surface.

## Open Questions

All resolved via Figma review (2026-05-26):

- QR flow direction: driver **scans** donor's QR (not displays). `scanner_screen.dart` stub handles this. ✓
- Safety checklist + photo upload required before pickup is confirmed. ✓
- Completion screen shows CO2 saved, meals provided, and gamification points. ✓
- Markers use food-category icons (e.g. `local_pizza`, `bakery_dining`), not generic pins. ✓

## Acceptance Criteria

- Driver sees open batches as food-category chip markers on a Google Map.
- Tapping a marker shows a preview card with "View Job →"; tapping that opens `JobDetailScreen`.
- Claiming uses a Firestore transaction; concurrent claim shows "Batch already taken" snackbar.
- Driver location is written to `driverLocations/{uid}` every 30 s while a batch is active.
- Pickup requires: QR scan of donor's code → safety checklist (all 3 ticked) → photo upload.
- Delivery requires: handover verification checkboxes + optional notes.
- Completion screen shows impact stats (CO2, meals) and points earned.
- Batch status progresses: `open → claimed → picked_up → delivered`.
- Every new screen has a widget test.
