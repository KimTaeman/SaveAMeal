---
title: "0005: Driver Profile"
description: "Dedicated profile screen for drivers to view and edit their identity, vehicle info, and avatar — with offline read support and bottom-nav Account tab wiring."
---

# PROP-0005: Driver Profile

**Status:** ACEEPTED
**Author:** architect
**Date:** 2026-06-03
**Spec:** (pending approval)
**Approved by:** Mew

---

## Problem

Drivers currently have no way to view or update their own identity inside the app. The `UserModel` holds a generic `name`, `email`, `phone`, and `photoUrl`, but driver-specific fields — vehicle type, licence plate, and emergency contact — have no home in the domain or the UI. The bottom nav "Account" tab (index 2 of `_DriverBottomNav`) is rendered but its `onDestinationSelected` handler ignores taps on it entirely; pressing it is a dead end.

The practical consequences are:

- Restaurant staff and beneficiaries cannot verify who is coming to collect a batch. A display name and avatar are the minimum trust signals needed for handover.
- Drivers cannot correct stale or incorrect profile data (e.g. a changed phone number or a new vehicle) without going outside the app.
- Vehicle and contact data collected during onboarding may go stale silently, because there is no in-app correction path.
- The app goes offline gracefully for batch discovery (Hive), but user identity is not cached locally at all, so the profile screen would be blank with no network — a poor experience for drivers who may work in areas with spotty connectivity.

## Proposed Solution

Introduce a dedicated `DriverProfile` domain entity (mirroring the pattern established by `DonorProfile`) that extends the generic identity fields with driver-specific fields: `vehicleType`, `licensePlate`, and `emergencyContact`. Back this with a `DriverProfileRepository` interface in the domain layer, a Firestore-backed implementation in the data layer, and a Hive local cache for offline reads.

Expose the feature as a `DriverAccountScreen` wired to the existing bottom nav Account tab (index 2 of `_DriverBottomNav`). A secondary "Edit Profile" sub-screen allows the driver to update their own editable fields. Avatar upload uses `flutter_secure_storage`-safe pre-signed URLs (exact storage backend TBD — see Open Questions).

This approach keeps the domain layer free of Flutter and backend imports, matches the established donor pattern so the Flutter engineer has a concrete reference, and delivers the offline read requirement through Hive without adding a new dependency.

## Alternatives Considered

### A — Extend `UserModel` and reuse a shared profile screen

Add driver-specific fields (`vehicleType`, `licensePlate`, `emergencyContact`) directly to the existing `UserModel` Freezed class and build a single generic `AccountScreen` that renders conditionally based on `UserRole`.

**Pros:** One model to maintain; no new domain entity; shared UI widget reduces duplication.

**Cons:** `UserModel` is already a god object — it carries `orgName`, `managerName`, `surplusTypes`, `operatingHours`, and `bannerUrl` that are purely donor concepts. Adding driver fields makes it wider and harder to reason about. Conditional rendering in a shared screen is a maintenance trap: donor and driver profiles will diverge (drivers need vehicle info; donors need operating hours), and every divergence adds another `if (role == driver)` branch. Freezed codegen for `UserModel` is regenerated for every role change, increasing build friction. **Effort: S** (shorter initially, M over time as roles diverge).

### B — Dedicated `DriverProfile` entity + feature-scoped screen (recommended)

Define `DriverProfile` as a pure Dart entity in `features/driver/domain/entities/`, declare a `DriverProfileRepository` interface in `features/driver/domain/repositories/`, implement it with a Firestore datasource + Hive cache in `features/driver/data/`, and build `DriverAccountScreen` in `features/driver/presentation/screens/`.

**Pros:** Follows the established donor pattern exactly, so the team has a proven template. Domain stays clean and role-specific. Hive cache is scoped to driver data only. Navigation wiring is isolated to the driver feature. No risk of contaminating donor or beneficiary flows. **Effort: M** (slightly more boilerplate, but low risk given the reference pattern).

**Cons:** One more entity and repository interface to maintain. If the team later unifies profile management across roles, this will need a refactor — but that is a deliberate future decision, not an accidental constraint.

### C — View-only profile, edits via admin panel

Render the driver's existing `UserModel` data read-only in a simple screen with no edit capability. Drivers contact an admin to update vehicle or contact info.

**Pros:** Minimal implementation — no write path, no avatar upload, no edit form. **Effort: S**.

**Cons:** Directly contradicts the user requirement (drivers must be able to update their own info). Creates operational overhead for the admin. Stale vehicle data is never corrected in-app. Does not satisfy the avatar upload acceptance criterion. **Rejected** as it does not meet the stated requirements.

## Open Questions

1. **Which fields are driver-editable vs admin-only?** The proposal assumes `name`, `phone`, `photoUrl`, `vehicleType`, `licensePlate`, and `emergencyContact` are self-service editable by the driver. Fields like `uid` and `email` are auth-managed and must be read-only in the profile UI. Confirmation needed from the team before spec is written.

2. **Avatar storage backend.** The backend stack is TBD (Firestore likely). Avatar images need a blob store — Firebase Storage is the natural companion to Firestore, but a CDN (Cloudinary, Imgix) may be preferred for image optimization. This decision affects the data-layer upload implementation and must be resolved before the spec finalises the `DriverProfileRepository` interface's `uploadAvatar` signature.

3. **Does vehicle info belong in the profile or in a separate driver-onboarding flow?** Vehicle type and licence plate could be collected once at registration and then maintained here, or they could live in a distinct "Vehicle" sub-section with its own edit screen. The spec boundary is unclear until this is decided. The proposal assumes vehicle fields are part of `DriverProfile`, but if onboarding is planned as a separate feature (PROP-0006 or similar), vehicle fields may need to be extracted.

4. **Hive box ownership.** No Hive adapters exist yet for user or driver data. A new Hive box (e.g. `driverProfileBox`) needs to be registered at app startup. This is a cross-cutting concern — confirm whether the Hive initialisation strategy (currently undefined) is centralised in `main.dart` or in a feature-level module.

## Acceptance Criteria

- Tapping the "Account" tab (index 2) in the driver bottom nav navigates to `DriverAccountScreen` without error on both Android and iOS.
- `DriverAccountScreen` displays the driver's name, avatar, phone number, vehicle type, and licence plate.
- If the device is offline, the screen shows the last-cached profile data (Hive) without throwing an error or displaying a blank state.
- The driver can navigate to an "Edit Profile" sub-screen and save changes to at least name, phone, vehicle type, and licence plate; changes persist to the backend and update the local Hive cache.
- The driver can upload or replace a profile photo; the new avatar is displayed immediately via `CachedNetworkImage` after a successful upload.
- `DriverProfile` domain entity has zero Flutter or backend imports.
- `DriverProfileRepository` is an abstract interface in the domain layer; the Firestore implementation lives in the data layer only.
- Every new screen (`DriverAccountScreen`, edit sub-screen) has a widget test.
- The feature does not modify `UserModel`, `DonorProfile`, or any existing donor presentation code.
