# QA Review — feature/onboarding-setup
Date: 2026-06-04
Reviewer: qa-engineer

## Verdict: CHANGES REQUESTED

---

## Findings

### [BLOCKING] Driver form has no validators — empty submit always succeeds

- File: `apps/mobile/lib/features/auth/presentation/screens/driver_onboarding_screen.dart`
- Detail: Every `TextFormField` and the `DropdownButtonFormField` in `DriverOnboardingScreen` has no `validator:` callback. `_formKey.currentState!.validate()` therefore always returns `true`, so `_submit()` will happily write a `DriverProfile` with `vehicleType: null`, `licensePlate: null`, `vehicleColor: null`, `cargoCapacity: null`, and `insurancePolicyNumber: null`. The driver ends up routed to `/driver` with a completely empty profile, defeating the purpose of the screen.
- Recommendation: Add validators. At minimum, Make & Model and License Plate should be required. Cargo Capacity (dropdown) should also be required. The same pattern already used in `BeneficiaryOnboardingScreen` can be copied directly.

---

### [BLOCKING] Tests do not satisfy the project test contract for any screen

- File: `apps/mobile/test/widget/features/auth/driver_onboarding_screen_test.dart`, `apps/mobile/test/widget/features/auth/beneficiary_onboarding_screen_test.dart`
- Detail: Both test files contain exactly 3 tests each, all of which are widget-presence smoke tests (`findsOneWidget` on static text). None of the following required scenarios are covered:
  - Happy path: fill all required fields, tap "Complete Setup", assert navigation to `/driver` or `/beneficiary`.
  - Validation errors: tap "Complete Setup" with empty required fields, assert error messages appear (beneficiary) or, once validators are added, driver error messages.
  - Skip flow: tap "Skip for now", assert navigation to the correct home route.
  - Loading state: assert `CircularProgressIndicator` appears while the async save is in progress and the submit button is disabled.
  - Error state: fake notifier throws, assert `SnackBar` appears and `_loading`/`_saving` is reset to `false`.
  - `onboarding_step_indicator.dart` has no dedicated widget test at all.
- Recommendation: Rewrite both test files to cover all scenarios listed above. Add a separate test file for `OnboardingStepIndicator` covering completed, current, and future step rendering. Follow the established pattern in `donor_dashboard_screen_test.dart` for fake provider injection and navigation assertions.

---

### [BLOCKING] `pumpAndSettle()` called without a duration — violates QA rule

- File: `apps/mobile/test/widget/features/auth/driver_onboarding_screen_test.dart` (lines 70, 75, 80), `apps/mobile/test/widget/features/auth/beneficiary_onboarding_screen_test.dart` (lines 86, 91, 96)
- Detail: All 6 `pumpAndSettle()` calls are unbounded. The QA rules explicitly require `pumpAndSettle(Duration)` — never unbounded — to prevent flaky tests when animations do not settle.
- Recommendation: Replace every `await tester.pumpAndSettle()` with `await tester.pumpAndSettle(const Duration(seconds: 3))`.

---

### [HIGH] `Colors.white` hardcoded — 4 violations across 3 files

- File: `apps/mobile/lib/shared/widgets/onboarding_step_indicator.dart` (lines 93, 106)
- File: `apps/mobile/lib/features/auth/presentation/screens/driver_onboarding_screen.dart` (line 256)
- File: `apps/mobile/lib/features/auth/presentation/screens/beneficiary_onboarding_screen.dart` (line 248)
- Detail: `Colors.white` is a hardcoded color. It will be incorrect in dark-mode or any future theme variant where the filled button background is not dark. Project convention forbids all hardcoded colors — use `cs.*` or `ac.*` only.
- Recommendation: Replace the `CircularProgressIndicator(color: Colors.white)` in both screen files with `color: cs.onPrimary`. Replace the two `Colors.white` values in `onboarding_step_indicator.dart` with `color: ac.onBrand` (if that token exists) or `color: cs.onPrimary`.

---

### [HIGH] Navigation inconsistency — `PopScope` present on driver screen only

- File: `apps/mobile/lib/features/auth/presentation/screens/driver_onboarding_screen.dart` (line 146), `apps/mobile/lib/features/auth/presentation/screens/beneficiary_onboarding_screen.dart`
- Detail: `DriverOnboardingScreen` wraps its `Scaffold` in `PopScope(canPop: false)`, preventing hardware back navigation. `BeneficiaryOnboardingScreen` has no `PopScope`, so the Android back gesture dismisses it entirely — the beneficiary can back-navigate out of onboarding without completing or skipping, which could leave the app in an unintended state (the `role_router_screen.dart` logic would re-route them back, but the UX is jarring and inconsistent).
- Recommendation: Add `PopScope(canPop: false)` to `BeneficiaryOnboardingScreen` to match the driver screen, or remove it from both screens and instead rely on the router's redirect guard. Decide on one policy and apply it uniformly.

---

### [MEDIUM] Step indicator dots have no semantic labels — screen reader inaccessible

- File: `apps/mobile/lib/shared/widgets/onboarding_step_indicator.dart` (lines 88–134)
- Detail: Each `_StepDot` is a bare `Container` with no `Semantics` wrapper. A screen reader using TalkBack or VoiceOver will either skip the dots or read them as unlabeled interactive elements. The `Step X of Y` text above the dots is readable but provides no state information per-dot (e.g., "Step 1, completed", "Step 2, current").
- Recommendation: Wrap the return value of `_StepDot.build` in `Semantics(label: 'Step $step of $totalSteps, ${isCompleted ? "completed" : isCurrent ? "current" : "not started"}', excludeSemantics: true)`.

---

### [MEDIUM] Refrigerated Storage switch not semantically associated with its label

- File: `apps/mobile/lib/features/auth/presentation/screens/driver_onboarding_screen.dart` (lines 219–231)
- Detail: The `Switch` and the `Text('Refrigerated Storage')` widget are siblings in a `Row` with no `Semantics` grouping. On Android/iOS with accessibility enabled, the switch is announced by its value only ("off" or "on") without the label. This fails WCAG 2.2 AA success criterion 1.3.1 (Info and Relationships) and 4.1.2 (Name, Role, Value).
- Recommendation: Wrap the entire `Row` in `Semantics(label: 'Refrigerated Storage', child: ...)` with `excludeSemantics: false`, or replace the manual row with a `SwitchListTile` which handles labelling automatically.

---

### [LOW] `_loading` not reset on successful navigation if `mounted` is false

- File: `apps/mobile/lib/features/auth/presentation/screens/driver_onboarding_screen.dart` (lines 96–98), `apps/mobile/lib/features/auth/presentation/screens/beneficiary_onboarding_screen.dart` (lines 72–74)
- Detail: Both `_submit`/`_handleSave` methods guard `context.go(...)` with `if (mounted)` but do not reset `_loading`/`_saving` to `false` before the guard check. If `mounted` is false at that point (e.g., the widget was removed from the tree between the await completing and the post-frame callback running), the widget is abandoned with `_loading = true`. On its own this is low risk because the widget is already unmounted, but it will cause a missed setState warning and could affect tests that pump the widget after an async operation completes.
- Recommendation: Add `setState(() => _loading = false)` immediately before `context.go(...)` in the success branch, mirroring what is already done correctly in the error branch.

---

### [INFO] `onboarding_step_indicator.dart` uses hardcoded `fontSize: 13`

- File: `apps/mobile/lib/shared/widgets/onboarding_step_indicator.dart` (lines 107, 127)
- Detail: The current-step and future-step number text styles use `TextStyle(fontSize: 13)` directly. Project convention requires all text styles to come from `Theme.of(context).textTheme`.
- Recommendation: Replace with `tt.labelSmall` or an equivalent theme text style token.

---

## Coverage gaps

| Scenario | `driver_onboarding_screen_test.dart` | `beneficiary_onboarding_screen_test.dart` |
|---|---|---|
| Renders title text | covered | covered |
| Renders submit button | covered (text only) | covered (text only) |
| Renders skip button | covered (text only) | covered (text only) |
| Loading state (CircularProgressIndicator + button disabled) | missing | missing |
| Happy path: fill + submit + navigate | missing | missing |
| Validation errors shown on empty submit | missing | missing |
| Skip navigates to home route | missing | missing |
| Error snackbar shown on save failure | missing | missing |
| `OnboardingStepIndicator` widget test | no test file exists | no test file exists |
| `pumpAndSettle` uses explicit duration | failing (unbounded) | failing (unbounded) |

---

## Summary

The feature/onboarding-setup branch introduces two functional onboarding screens and a shared step-indicator widget. The implementation has one critical functional defect (driver form validators are absent, allowing silent empty-profile saves), and the accompanying tests are insufficient to catch it or any other scenario beyond basic render presence. Three convention violations (`Colors.white`, hardcoded `fontSize`) and two accessibility issues (unlabelled step dots, unlabelled switch) also require fixes before merge. The `PopScope` inconsistency between the two screens should be resolved to a single policy. No unbounded `ListView` usage was found and no remote images are loaded on these screens, so performance is clean.
