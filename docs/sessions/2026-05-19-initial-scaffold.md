---
Date: 2026-05-19
Member: khinnadiko
Agent: architect + flutter-engineer
Task: Repository audit and initial scaffold fixes
---

## Context

Audit against Assignment Details.txt and Enterprise Mobile Handbook revealed 12 discrepancies. The two blocking D1 deliverable gaps were: (1) no `.github/workflows/` CI pipeline, and (2) `pubspec.yaml` missing all required dependencies. The `lib/` directory held only the default Flutter counter demo with no Clean Architecture structure.

## Plan

1. [x] Create `.github/workflows/ci.yml` — 3 jobs: format/analyze/test, web build, android build
2. [x] Rewrite `pubspec.yaml` — full Flutter + Firebase + Riverpod + GoRouter stack
3. [x] Fix `analysis_options.yaml` — add `always_use_package_imports`, `avoid_print`
4. [x] Add 5 missing agent definitions — accessibility-auditor, performance-analyst, platform-ios, platform-android, backend-contract
5. [x] Create `.claude/skills/feature-flag/` skill
6. [x] Create `tools/scan_secrets.sh` and `.claude/hooks/scan-on-save.sh`
7. [x] Create `.claude/hooks/format-on-save.sh`
8. [x] Update `settings.json` — wire new hooks into PreToolUse and PostToolUse
9. [x] Write ADRs 0001–0004 for all stack decisions
10. [x] Replace counter demo with Clean Architecture scaffold — core/, shared/, app/
11. [x] Update widget tests for new app structure
12. [x] Add `integration_test/app_test.dart` stub

## Decisions Made

- **Hive over Drift** (ADR-0003): Firestore document model maps naturally to Hive boxes; Hive works on Web without extra config; Drift needs a web shim.
- **`Firebase.initializeApp()` without explicit options**: Deferred until `flutterfire configure` is run to generate `lib/firebase_options.dart`. A TODO comment marks the location.
- **Widget tests bypass Firebase**: Tests target `AppTheme` and router infrastructure directly, avoiding the need to initialise Firebase in unit test runs.
- **Secret scan as PreToolUse**: Blocks writes before they happen rather than scanning after (PostToolUse would be too late to prevent a committed secret).

## Handoff

Next session must:
1. Run `flutterfire configure` to generate `lib/firebase_options.dart` and update `main.dart`
2. Decide on the application theme (banking / healthcare / inventory / chat) — triggers first `/new-proposal`
3. Scaffold `packages/auth/`, `packages/networking/` shared packages
4. Implement first feature flow via `/new-proposal` → `/new-spec` → `/new-feature`

## Review needed from

architect — verify Clean Architecture layer boundaries in scaffold are correct before any feature work begins
