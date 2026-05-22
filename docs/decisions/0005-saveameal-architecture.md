---
title: "0005: Adopt SaveAMeal three-sided marketplace architecture with Firebase backend"
description: "Formalises the conceptual and implementation architecture from SaveAMeal_Architecture.docx as the canonical project design."
---

# 0005 — SaveAMeal Architecture

**Status:** ACCEPTED
**Author:** Kim Taeman (architect)
**Date:** 2026-05-22

## Problem

The project was scaffolded with a generic Clean Architecture template and a TBD backend. This ADR locks in the domain model, technology choices, and folder conventions for the SaveAMeal food-rescue marketplace, based on the approved architecture document.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Firebase (Auth + Firestore + Storage + FCM + Cloud Functions) | Real-time listeners built-in, zero SQL, managed auth, team has no SQL experience, fast to ship | Vendor lock-in, limited complex querying |
| 2 | Supabase (PostgreSQL + Edge Functions) | Open-source, SQL power, self-hostable | Team has zero SQL experience; 10-day window is too short to ramp up |
| 3 | Custom REST API (Node/Python) | Full control | Requires building auth, realtime, storage from scratch; unrealistic for 10-day scope |

## Decision

**Chosen:** Option 1 — Firebase

Firebase provides five managed services (Auth, Firestore, Storage, FCM, Cloud Functions) that cover every SaveAMeal requirement without custom backend code. Real-time Firestore listeners are the killer feature: they power live driver tracking and instant impact dashboard updates with zero polling. The only custom server code needed is four Cloud Functions as Firestore document triggers.

## Domain Model

Three user roles: **Donor** (surplus food supply), **Driver/Volunteer** (logistics), **Beneficiary** (food distribution). The platform coordinates — it does not transport food or store it physically.

Four Firestore collections:
- `users` — one document per auth UID; `role` field drives the Role Router
- `batches` — core entity; status lifecycle `open → claimed → picked_up → delivered → closed`
- `driverLocations` — high-frequency writes (~30 s); kept separate from batches to limit listener bandwidth
- `impactMetrics` — pre-aggregated counters updated by `onDeliveryComplete` Cloud Function

Four Cloud Functions:
- `onBatchCreated` — FCM to nearby drivers
- `onBatchClaimed` — FCM to donor + beneficiary ("magic moments")
- `onDeliveryComplete` — atomic `FieldValue.increment()` on impact counters
- `cleanupLocations` (scheduled daily) — prune stale driverLocations docs

Race condition on batch claim is handled by a Firestore transaction that reads and validates `status == "open"` before writing.

## Folder Conventions

Feature folders follow Clean Architecture (`domain/`, `data/`, `presentation/`) named after the three roles plus `auth`:
```
features/donor/
features/driver/
features/beneficiary/
features/auth/
services/   ← thin wrappers over Firebase SDK (AuthService, FirestoreService, StorageService, QrService, LocationService)
core/models/ ← Freezed Firestore document models
core/constants/ ← FirestoreConstants (collection names)
```

The `services/` layer is the only place that imports Firebase packages. Feature datasources delegate to services, keeping domain and presentation layers Firebase-free.

## State Management Note

The architecture document recommends `provider` for its lower learning curve in a 10-day window. The repo scaffold uses `flutter_riverpod` (CLAUDE.md convention). **Riverpod is retained** — it is a superset of Provider, equally approachable, and already in pubspec. This avoids a mid-project migration and keeps the existing lint rules intact.

## Reversal Cost

High — swapping Firebase for another backend requires rewriting all five service classes and the four Cloud Functions. Domain and presentation layers are deliberately Firebase-free to make this tractable if needed post-graduation.

## Consequences

Easier: real-time UI updates, zero auth/storage infrastructure, rapid iteration.
Harder: complex relational queries, offline-first behaviour (out of scope for this build).
Follow-up: run `flutterfire configure` to generate `firebase_options.dart` before any Firebase call works; add Google Maps API key to Android/iOS manifests; configure Firestore security rules per the role matrix in the architecture document.
