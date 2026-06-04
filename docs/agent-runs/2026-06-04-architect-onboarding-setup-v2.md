# Architect Review v2 — feature/onboarding-setup
Date: 2026-06-04
Reviewer: architect

---

## Verdict: APPROVED (with two tracked follow-ups)

All three v1 BLOCKING issues are resolved. The four HIGH issues are resolved. No new blocking violations were found in this pass. Two follow-up items are recorded below as MEDIUM and LOW respectively; neither is severe enough to block merge, but both must be addressed before the next stable release cut.

---

## Resolved findings (from v1)

- BLOCKING: `Colors.white` in `onboarding_step_indicator.dart`, `driver_onboarding_screen.dart`, `beneficiary_onboarding_screen.dart` — replaced with `cs.onPrimary` throughout. Verified.
- BLOCKING: Inline `TextStyle(color: Colors.white, ...)` in `_StepDot` — replaced with `tt.labelSmall?.copyWith(...)`. Verified.
- BLOCKING: No widget tests for the three new files — 13 tests now present and passing. Verified.
- HIGH: Silent `catch (_)` in beneficiary branch of `_routeByRole` — now `catch (e, st)` with `AppLogger.error(...)`. Verified at line 208–213 of `role_router_screen.dart`.
- HIGH: No role guards on `/onboarding/driver` and `/onboarding/beneficiary` — `redirect` callbacks added in `router.dart` lines 78–95, checking `user.role`. Verified.
- HIGH: `_loading` never reset on error path in `DriverOnboardingScreen` — now reset via `finally` block at line 122–124. Verified.
- HIGH: `BeneficiaryOnboardingScreen` missing `PopScope(canPop: false)` — added at line 128. Verified.
- ADR-0017 written at `docs/decisions/0017-async-profile-check-in-role-router.md`. Verified.

---

## Remaining / new findings

### [MEDIUM] `_saving` reset lives only in `catch`, not in `finally` — diverges from driver pattern

- File: `apps/mobile/lib/features/auth/presentation/screens/beneficiary_onboarding_screen.dart`, lines 75–87
- Detail: `_saving` is set to `true` at line 58 and reset to `false` only inside the `catch` block (line 82). On the success path the widget navigates via `context.go('/beneficiary')`, which disposes the widget; the reset never executes. This is currently harmless because Flutter discards widget state on navigation. However, the pattern is asymmetric with `DriverOnboardingScreen`, which uses a `finally` block to guarantee the reset runs regardless of outcome. If the success path ever changes to a `push` (rather than `go`), or if `context.go` throws before the widget is disposed, the screen will remain mounted with `_saving = true` and the submit button permanently disabled. The `DriverOnboardingScreen` pattern is the established convention (see v1 HIGH finding) and the beneficiary screen should match it.
- Recommendation: Move `setState(() => _saving = false)` from the `catch` block into a `finally` block, exactly mirroring the driver screen. Remove the `setState` call from inside the `catch` and instead handle only the `SnackBar` there. This is a one-line structural change with zero risk.

### [LOW] `_StepConnector` dimensions `width: 40` and `height: 2` are magic numbers with no Spacing token

- File: `apps/mobile/lib/shared/widgets/onboarding_step_indicator.dart`, lines 167–169
- Detail: `Spacing` only defines 6 values: `xs=4, sm=8, md=16, lg=24, xl=32, xxl=48`. Neither `40` nor `2` maps to any of them. The `height: 2` is a border/stroke dimension, not a spatial rhythm value — the Spacing convention is explicitly about layout spacing, so `height: 2` is defensible as a component-internal design constant. The `width: 40` is a fixed layout dimension for a shared widget that will look correct only while the app targets its current minimum screen width; on narrow viewports (320 dp) with more than 3 steps it can overflow. These are not Spacing rule violations in the strict sense (the rule is "no hardcoded spacing magic numbers — use the spacing scale"), but `width: 40` is a layout size that has no semantic meaning as written.
- Recommendation: For `height: 2`, extract to a local `const double _connectorThickness = 2.0` with a comment explaining it is a stroke size, not a spacing value — this clarifies intentionality. For `width: 40`, consider making it a named parameter with a default (`connectorWidth = 40.0`) so callers can adjust it, or use `Expanded` / `flexible` layout inside the `Row` to make connector width proportional to available space. Do not block the merge on this; track as a polish item.

### [INFO] `StateError` fallback in driver branch routes to `/driver`, not `/onboarding/driver`

- File: `apps/mobile/lib/features/auth/presentation/screens/role_router_screen.dart`, line 195
- Detail: When `driverProfileProvider.future` throws a `StateError` (which Riverpod emits when a provider is disposed between the `read` and the `await`), the fallback is `context.go('/driver')`. This sends a driver whose provider was disposed directly to the dashboard, bypassing the onboarding check. This is a safe defensive choice — a `StateError` here almost always means the user is navigating away and the provider is being cleaned up — but the intent is not obvious from the code. The beneficiary catch-all by contrast falls back to `/onboarding/beneficiary`, which is stricter (it forces onboarding rather than assuming the profile is complete).
- Recommendation: No change required; the current behaviour is acceptable as documented in ADR-0017. Add a comment inline: `// Provider disposed mid-flight — assume profile exists and land on dashboard` to make the intent explicit and prevent a future reviewer from "fixing" it to `/onboarding/driver`.

### [INFO] `SafeArea` `child:` indentation is misaligned in `BeneficiaryOnboardingScreen`

- File: `apps/mobile/lib/features/auth/presentation/screens/beneficiary_onboarding_screen.dart`, lines 131–132
- Detail: `child: SingleChildScrollView(` is at the same indent level as `body: SafeArea(`, which suggests `dart format` was not run after the `PopScope` wrapper was added. This is a formatting violation (`dart format .` is required before every commit per CLAUDE.md). It will not cause a compile error or a runtime issue, but it makes the widget tree harder to read and will produce a diff noise on the next format pass.
- Recommendation: Run `dart format apps/mobile/lib/features/auth/presentation/screens/beneficiary_onboarding_screen.dart` before the merge commit. `flutter analyze` will pass because this is a whitespace issue, not a semantic one — the formatter is the correct enforcement tool here.

---

## Checklist

- [x] Layer boundaries — no domain files modified; all new files are in `presentation/` or `shared/widgets/`
- [x] Package imports — all imports use `package:saveameal/...` convention; no relative imports found
- [x] No hardcoded `Colors.*` — PASSED (all replaced with `cs.*`)
- [x] No inline `TextStyle` outside `textTheme` — PASSED (`tt.labelSmall?.copyWith(...)` used throughout)
- [x] No unbounded `ListView` — not applicable (no `ListView` in new files)
- [x] No hardcoded spacing via `Spacing.*` — PASSED for layout spacing; two connector dimensions are non-Spacing values (see LOW finding)
- [x] Widget tests for every new screen — PASSED (13 tests)
- [x] Role guards on onboarding routes — PASSED
- [x] Error handling logs before fallback navigation — PASSED
- [x] ADR written — ADR-0017 present and ACCEPTED
- [~] `_saving` reset uses `finally` — FAILED in beneficiary screen (see MEDIUM finding)
- [~] `dart format` clean — FAILED in beneficiary screen SafeArea indentation (see INFO finding)

---

## Summary

The branch is in a mergeable state. The three blocking violations from v1 (hardcoded colors, inline `TextStyle`, missing tests) are all cleanly resolved. The role guards and logging are now consistent with project conventions. The two residual items — `_saving` not in `finally`, and the formatting regression in `BeneficiaryOnboardingScreen` — are low-risk but should be cleaned up before the next release cut. The `_StepConnector` magic numbers are acknowledged design constants; extracting them to named locals would improve readability without changing behaviour. No architecture boundary violations were found in this pass.
