# Session: 2026-06-04 — driver-impact

**Date:** 2026-06-04
**Member:** KimTaeman
**Agent:** flutter-engineer
**Task:** Implement DriverImpactScreen (Impact tab in driver bottom nav)

---

## Context

SPEC-0004 (Driver flow) is APPROVED. The bottom nav already had an "Impact" tab wired at index 1
in both `driver_map_screen.dart` and `driver_account_screen.dart`, but with no route. Design
reference: `Simplified Driver Impact Screen (Updated Nav).png`.

## Plan

1. Domain entities: `DriverImpact`, `LeaderboardEntry` (pure Dart)
2. Repository interface: `DriverImpactRepository`
3. Use cases: `GetDriverImpactUsecase`, `GetLeaderboardUsecase`
4. Data models: `DriverImpactModel`, `LeaderboardEntryModel` (Freezed + JSON)
5. Datasource: reads `users/{uid}` for impact stats; `leaderboard/{period}` for top drivers
6. Repository impl + providers (@riverpod)
7. Screen: rank card, stats row, leaderboard section, wired bottom nav
8. Router: `/driver/impact` route added
9. Nav taps wired in map + account screens
10. Widget test (10 cases)

## Progress

- [x] Domain entities
- [x] Repository interface
- [x] Use cases
- [x] Freezed models (requires `build_runner`)
- [x] Datasource + repository impl
- [x] Providers
- [x] Screen
- [x] Router route
- [x] Nav wired in map + account screens
- [x] Widget test

## Decisions Made

- Separate `DriverImpactRepository` rather than extending `DriverRepository` — keeps impact/leaderboard concern isolated from the delivery flow
- Leaderboard Firestore schema: `leaderboard/{period}` doc with `entries: [...]` array — simplest read pattern, Cloud Function writes the ranked list on each delivery
- `_buildRepo()` helper in provider mirrors `driver_profile_provider.dart` pattern (direct Firestore.instance) for consistency
- `1.3K` formatting for sproutPoints ≥ 1000

## Blockers / Open Questions

- `build_runner` must be run to generate `.freezed.dart` + `.g.dart` for `DriverImpactModel` and `LeaderboardEntryModel`
- "View Full Leaderboard" tap is a no-op stub — full leaderboard screen is out of scope for this session

## Handoff

Run `dart run build_runner build --delete-conflicting-outputs` to generate Freezed/codegen files.
Then run `flutter test test/widget/driver/driver_impact_screen_test.dart`.

Firestore schema required for live data:
- `users/{uid}`: add fields `rank`, `totalDrivers`, `mealsSaved`, `sproutPoints`, `rankProgressCurrent`, `rankProgressTarget`, `currentRankName`, `nextRankName`
- `leaderboard/thisMonth`: doc with `entries: [{rank, driverName, zone, uid, score, avatarUrl?}]`

**Review needed from:** qa-engineer
