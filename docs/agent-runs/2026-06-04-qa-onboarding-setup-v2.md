# QA Review v2 — feature/onboarding-setup
Date: 2026-06-04
Reviewer: qa-engineer

## Verdict: CHANGES REQUESTED

---

## Resolved findings (from v1)

- [BLOCKING] Driver form validators missing — resolved. Make & Model, License Plate, and Cargo Capacity all have validators.
- [BLOCKING] Tests did not cover required scenarios — resolved. 5 tests per screen + 3 for OnboardingStepIndicator = 13 total, all passing.
- [BLOCKING] `pumpAndSettle()` called without duration — resolved. All calls use `pumpAndSettle(const Duration(seconds: 3))`.
- [HIGH] `Colors.white` hardcoded in 3 files — resolved. `cs.onPrimary` used throughout.
- [HIGH] `PopScope(canPop: false)` missing from BeneficiaryOnboardingScreen — resolved.
- [MEDIUM] Refrigerated Storage switch not semantically labelled — resolved via `SwitchListTile`.
- [MEDIUM] Step indicator dots had no semantic labels — resolved. `Semantics` wrappers with full labels added to all three dot states.
- [INFO] Hardcoded `fontSize: 13` in OnboardingStepIndicator — resolved. `tt.labelSmall?.copyWith(...)` used.

---

## Remaining / new findings

### [MEDIUM] `_saving` flag not reset in `finally` — beneficiary screen only

- File: `apps/mobile/lib/features/auth/presentation/screens/beneficiary_onboarding_screen.dart` lines 54–88
- Detail: `_handleSave` has no `finally` block. On the success path `context.go('/beneficiary')` is called inside `if (mounted)`, unmounting the widget, so `_saving` is abandoned as `true`. On the error path, `setState(() => _saving = false)` is correctly called inside `catch`. The driver screen has a symmetric `finally { if (mounted) setState(() => _loading = false); }` (line 122 of `driver_onboarding_screen.dart`). Because `PopScope(canPop: false)` prevents hardware-back and onboarding screens have no in-app back button, the risk of a user reaching this screen again in the current navigation stack is low. However, if the router ever pops back to this screen (e.g., a future deep-link or GoRouter redirect), the button will be permanently disabled and the spinner will spin forever with no recovery path.
- Recommendation: Add `finally { if (mounted) setState(() => _saving = false); }` to `_handleSave`, mirroring the driver screen pattern exactly. This removes the asymmetry between the two screens and closes the future-proofing risk.

---

### [MEDIUM] `dart format` not run before submission — 5 files reformatted by CI

- Files: `lib/features/auth/presentation/screens/beneficiary_onboarding_screen.dart`, `lib/features/auth/presentation/screens/driver_onboarding_screen.dart`, `lib/shared/widgets/onboarding_step_indicator.dart`, `test/widget/features/auth/driver_onboarding_screen_test.dart`, `test/widget/features/auth/beneficiary_onboarding_screen_test.dart`
- Detail: Running `dart format --set-exit-if-changed` against the 6 changed files reported 5 changed files. This means the PR would have failed the `dart format --set-exit-if-changed .` CI gate. (The formatter corrected trailing-comma and indentation issues introduced during the rewrite.)
- Recommendation: Run `dart format .` from `apps/mobile/` before every commit. The CI gate `dart format --set-exit-if-changed .` is mandatory and will block the pipeline.

---

### [LOW] `onboarding_step_indicator_test.dart` — test 2 is a non-assertion

- File: `apps/mobile/test/widget/features/auth/onboarding_step_indicator_test.dart` lines 20–27
- Detail: The test `'renders correct number of dots'` uses `expect(find.byType(Container), findsWidgets)`. `findsWidgets` passes as long as at least one `Container` exists anywhere in the tree — which is always true in a `MaterialApp` scaffold. The assertion provides zero signal: it cannot detect the wrong number of dots, missing dots, or a regression that removes dots entirely. The other two tests (`'shows correct step label'` and `'shows Step 2 of 2 for onboarding screens'`) are meaningful text-content assertions and pass correctly.
- Recommendation: Replace the dot-count test with a targeted assertion. Since each dot is a `Semantics` widget with a known label pattern, `find.bySemanticsLabel(RegExp(r'Step \d of \d'))` can be counted precisely: `expect(find.bySemanticsLabel(RegExp(r'Step \d of 2')), findsNWidgets(2))` for a 2-step indicator. Also consider adding tests for the completed-dot state (checkmark icon present) and the future-dot state (outlined circle, no checkmark).

---

### [LOW] Beneficiary validation test covers only one of four required fields

- File: `apps/mobile/test/widget/features/auth/beneficiary_onboarding_screen_test.dart` lines 145–153
- Detail: The `'empty submit shows validation error for org name'` test taps "Complete Setup" with all fields empty and asserts only `'Organization name is required'`. The form also validates Organization Type (`'Organization type is required'`), Headquarters Address (`'Address is required'`), and Primary Contact Email (`'Email is required'`). These validators exist in the production code and the test silently ignores them. While the validators themselves work (they fire on the full submit), there is no test that would catch a regression where those validators are accidentally removed.
- Recommendation: Either extend the existing test to also `expect` the type, address, and email error messages, or add a second test `'empty submit shows all required field errors'` that checks all four messages are visible simultaneously.

---

### [LOW] Driver validation test covers only 2 of 3 required field errors

- File: `apps/mobile/test/widget/features/auth/driver_onboarding_screen_test.dart` lines 136–144
- Detail: The `'empty submit shows validation errors'` test asserts `'Make & model is required'` and `'License plate is required'` but does not assert `'Cargo capacity is required'`. The dropdown validator exists in production and would be missed by a regression that removes it.
- Recommendation: Add `expect(find.text('Cargo capacity is required'), findsOneWidget)` to the existing validation test.

---

### [INFO] Error snackbar styling inconsistent between screens

- Files: `apps/mobile/lib/features/auth/presentation/screens/driver_onboarding_screen.dart` line 116–120, `apps/mobile/lib/features/auth/presentation/screens/beneficiary_onboarding_screen.dart` line 82–85
- Detail: The driver screen's error snackbar sets `backgroundColor: Theme.of(context).colorScheme.error`. The beneficiary screen uses `const SnackBar(content: Text('...'))` with no background color, falling back to the Material default. Both screens show the same user-facing message but with different visual treatment.
- Recommendation: Add `backgroundColor: Theme.of(context).colorScheme.error` to the beneficiary screen's error snackbar to match the driver screen.

---

## Coverage assessment

| Scenario | driver_onboarding_screen_test | beneficiary_onboarding_screen_test | onboarding_step_indicator_test |
|---|---|---|---|
| Renders title and buttons | covered | covered | — |
| Skip navigates to home route | covered | covered | — |
| Empty submit shows validation errors | covered (2 of 3 fields checked) | covered (1 of 4 fields checked) | — |
| Valid submit navigates to home route | covered | covered | — |
| Error snackbar shown on save failure | covered | covered | — |
| Loading state (spinner + disabled button) | missing | missing | — |
| Step label text | — | — | covered |
| Dot count meaningful assertion | — | — | failing (non-assertion) |
| Completed dot state (checkmark) | — | — | missing |
| Future dot state (outlined) | — | — | missing |

**All 13 tests pass.** `flutter analyze` passes with zero issues in the feature files (one pre-existing `avoid_print` in `test/debug_driver_test.dart` is unrelated to this branch). `dart format` required reformatting 5 files — this would have failed the CI gate.

**Test pattern soundness:**
- `UncontrolledProviderScope` with a pre-primed container and `container.listen(..., fireImmediately: true)` is the correct pattern for preventing `authStateProvider` auto-disposal between pump calls. It is sound and should be documented as the canonical approach for async-submit tests.
- `FormFieldState.didChange()` is the correct way to set dropdown values in widget tests without triggering the overlay. It is sound and avoids the well-known overlay-flakiness issue with `DropdownButtonFormField` in test environments.
- `addTearDown(container.dispose)` is correctly registered in all tests that use a manual `ProviderContainer`.

---

## Summary

Seven of the eight v1 findings are fully resolved. Two new MEDIUM findings require fixes before merge: the missing `finally` block in `BeneficiaryOnboardingScreen._handleSave` (asymmetry with the driver screen, latent permanent-spinner bug if the screen is ever revisited) and the fact that `dart format` was not run before submission (5 files were reformatted, which would have failed the CI gate). Three LOW findings cover test coverage gaps that leave validators silently unguarded against regression. The `UncontrolledProviderScope` and `FormFieldState.didChange()` test patterns are sound and approved for ongoing use.
