---
title: "0004: Use Firebase (Auth, Firestore, Crashlytics) as the backend platform"
description: "Firebase chosen as the managed backend, authentication, and observability platform per assignment requirements."
---

# 0004 — Backend Stack: Firebase

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-05-19

## Problem

The app requires a managed backend providing authentication (including biometric/passkey session resumption), a scalable database with built-in offline sync, and crash reporting. The solution must meet the assignment's mandatory requirements (R1–R4) and support the team's multi-agent development workflow without requiring a custom server.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Firebase (Auth + Firestore + Crashlytics) | Assignment-required; managed infrastructure; Firestore offline sync built-in; first-class Flutter SDK; Auth supports OAuth and platform keystore integration | Vendor lock-in; Firestore query limitations compared to SQL; cost at scale |
| 2 | Supabase (Auth + Postgres) | Open source; full SQL; better complex query support | Not required by the assignment; no built-in Flutter offline sync |
| 3 | Custom REST backend + JWT | Full control; no vendor lock-in | Outside assignment scope; requires building auth, sync, and crash reporting from scratch |

## Decision

**Chosen:** Option 1 — Firebase

Firebase is explicitly required by the assignment (R1: Firebase Authentication; R4: Google Firestore, Firebase Crashlytics). Firestore's native offline persistence complements the Hive cache layer (ADR-0003), providing real-time sync and conflict resolution without custom server code. Firebase Auth supports the required email/password, OAuth, and biometric session resumption flows via `flutter_secure_storage` and platform keystores.

## Reversal Cost

High — Firestore-specific data models, security rules, and Auth integration permeate the Data layer. Migrating to Supabase would require rewriting all Data layer datasources and repositories, replacing Firestore Security Rules with Postgres RLS, and re-implementing Auth flows. Domain and Presentation layers are unaffected.

## Consequences

- `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) kept out of version control via `.gitignore`
- FlutterFire CLI must be run to generate `lib/firebase_options.dart`: `flutterfire configure`
- Firestore Security Rules are a required review gate — the backend-contract agent reviews before any production deploy
- Crashlytics SDK initialised before `runApp()` in `main.dart` to catch all fatal errors
- Remote Config used for feature flags (see feature-flag skill)
