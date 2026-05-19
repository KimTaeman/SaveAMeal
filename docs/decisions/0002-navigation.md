---
title: "0002: Use GoRouter for navigation with authentication guards"
description: "GoRouter chosen as the declarative, deep-link-capable router with first-class auth guard support."
---

# 0002 — Navigation: GoRouter

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-05-19

## Problem

The app requires a route-based navigation solution that supports deep links, authentication guards that redirect unauthenticated users, Web-compatible URL paths, and integration with the Riverpod auth state. The assignment mandates at least five distinct functional flows.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | GoRouter | Flutter-team maintained; deep links; `redirect` callbacks for auth guards; Web-first URL semantics; Material 3 integration | Slightly verbose for trivial apps |
| 2 | auto_route | Code-generated, type-safe route arguments | Third-party; code-gen adds additional build step; less community support |
| 3 | Navigator 2.0 (raw) | Total control over back stack | Extremely verbose; not practical for a team project; no built-in auth guards |

## Decision

**Chosen:** Option 1 — GoRouter

GoRouter is the Flutter team's official declarative router. Its `redirect` callback accepts a `BuildContext` and can read Riverpod auth state via `ref.read`, enabling clean authentication guards without coupling navigation logic to widget code. Named routes and deep links are first-class, which satisfies the multi-flow requirement, and Web builds get semantic URL paths without additional configuration.

## Reversal Cost

Low-Medium — all route declarations are centralised in `lib/app/router.dart`. Migrating to auto_route requires swapping the router config and regenerating route classes, but screens themselves are unchanged.

## Consequences

- All routes declared in `lib/app/router.dart` (enforced by flutter-engineer agent)
- Auth guard implemented in the `redirect` callback reading Riverpod `authStateProvider`
- Every new screen must be added to `router.dart` before it can be navigated to
- Web builds automatically expose `/route-name` URL paths
