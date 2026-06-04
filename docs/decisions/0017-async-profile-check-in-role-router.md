# 0017 — Async profile-completion check in role_router_screen

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-04

## Problem

After a user authenticates, the app must determine whether their role-specific profile is complete before routing them to the dashboard or to an onboarding screen. This check is inherently asynchronous (it requires a Firestore read) and must produce a navigation side-effect. Three candidate locations exist for this logic: inside the GoRouter redirect callback, inside a dedicated splash/loading screen, or inside the existing `RoleRouterScreen` widget's `AsyncValue` consumer. The choice determines where async error handling lives, how testable the routing logic is, and whether the navigation layer takes on business-logic responsibility.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Perform the async profile check inside `RoleRouterScreen` using `ref.watch` on a profile provider and navigate imperatively in `whenData` | Minimal new abstraction; integrates naturally with the existing Riverpod async widget pattern; loading and error states are directly renderable | Navigation logic sits inside a widget; `Future<void>` returned by the async callback is fire-and-forget; errors must be explicitly caught and logged or they are silently swallowed |
| 2 | Perform the check inside GoRouter's `redirect` callback by awaiting the profile provider | Navigation logic stays in the router layer; redirect runs before any widget is built | GoRouter `redirect` is synchronous by design; using `ref.read` inside `redirect` to force synchronous reads is fragile against cold-start race conditions; testing requires a full router setup |
| 3 | Introduce a dedicated `ProfileCheckScreen` (splash) that owns the async read, renders a loading indicator, and pushes the correct route on completion | Separation of concerns is clean; loading UI is explicit and testable; error states are first-class | Adds a route and a screen purely for orchestration; increases navigation stack depth; back-button behaviour must be suppressed |

## Decision

**Chosen: Option 1 — async profile check inside `RoleRouterScreen`.**

`RoleRouterScreen` already exists as an orchestration screen whose sole purpose is to route by role; extending it with an async profile-completeness check is a narrow, cohesive addition that avoids introducing a new route or fighting GoRouter's synchronous redirect model. The `AsyncValue` pattern from Riverpod handles loading and error rendering at the widget level with no additional scaffolding. The fire-and-forget `Future<void>` is acceptable provided all catch blocks call `AppLogger.error` before performing fallback navigation — this constraint is enforced by the HIGH finding in the onboarding-setup PR review (2026-06-04).

## Reversal Cost

Medium. Migrating to Option 3 requires: adding a new route in `router.dart`, creating a `ProfileCheckScreen`, moving the async logic out of `RoleRouterScreen`, and updating widget tests. The domain and data layers are unaffected. Estimated scope: 3–5 files.

## Consequences

**Easier:** Profile-completeness routing logic is co-located with role-routing logic in a single screen, making the full post-auth flow readable in one file. Riverpod's `AsyncValue` handles the loading spinner automatically.

**Harder:** The widget carries imperative navigation side-effects, making it harder to unit-test the routing decisions in isolation from the widget lifecycle. Every catch block in `_routeByRole` must be kept narrow and must always log before navigating — this is a convention that must be enforced via review, not the type system. Any future addition of a new role requires updating `_routeByRole` in this screen.
