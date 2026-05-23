---
title: "0001: Auth Flow — Firebase email/password + role-based routing"
description: "Implement sign-in, registration, and role-based dashboard routing using Firebase Auth and Firestore."
---

# PROP-0001: Auth Flow — Firebase email/password + role-based routing

**Status:** ACCEPTED  
**Author:** KimTaeman  
**Date:** 2026-05-22  
**Spec:** [SPEC-0001](../tech-specs/0001-auth-flow.md)  
**Approved by:** KimTaeman

---

## Problem

The app scaffold exists but no user can authenticate. Every feature (Donor, Driver, Beneficiary) requires a known user identity and role. Without auth, no route is protected and no role-specific dashboard can be reached.

## Proposed Solution

Use Firebase Auth (email/password) as the identity provider. On registration, write a Firestore `users/{uid}` document containing `name`, `email`, `role`, and optional profile fields. On sign-in, fetch that document to hydrate the domain `AppUser` entity.

A Riverpod `StreamProvider<AppUser?>` watches `authStateChanges()` and is consumed by a GoRouter redirect guard. On auth, the `RoleRouterScreen` inspects the role and pushes to the correct dashboard route.

## Alternatives Considered

### A — Google Sign-In

OAuth is a better UX but adds platform keystore configuration (SHA-1 fingerprint, GoogleService-Info.plist). **Rejected:** out of scope for MVP; can be layered on later via the same `AuthRepository` interface.

### B — Anonymous auth + upgrade flow

Let users browse as anonymous, then upgrade to a full account. **Rejected:** SaveAMeal requires a known role before any meaningful action; anonymous users can't be assigned to a batch.

## Open Questions

None — all design questions resolved before this proposal was accepted.

## Acceptance Criteria

- User can register with name, email, password, and a role (Donor / Driver / Beneficiary)
- User can sign in with email and password
- Unauthenticated users are redirected to `/login` for any protected route
- Authenticated users landing on `/login` or `/register` are redirected to `/role-router`
- `/role-router` immediately pushes to `/donor`, `/driver`, or `/beneficiary` based on the stored role
- Domain layer (`AppUser`, `AuthRepository`, use cases) has zero Flutter or Firebase imports
