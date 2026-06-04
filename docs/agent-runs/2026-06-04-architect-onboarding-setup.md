# Architect Review — feature/onboarding-setup
**Reviewer:** architect
**Session ID:** onboarding-setup
**PR / Branch:** feature/onboarding-setup
**Date:** 2026-06-04

---

## Verdict: CHANGES REQUESTED

Three BLOCKING issues must be resolved before merge: hardcoded `Colors.*` values in a shared widget and two screens, a silent-catch without logging in the role router that can mask production errors and misroute users, and missing widget tests for every new screen and the new shared widget. The remaining issues are HIGH or MEDIUM and must be addressed before release.

---

## Findings

### [BLOCKING] Hardcoded Colors.white in shared widget and onboarding screens

- **Files:**
  - `lib/shared/widgets/onboarding_step_indicator.dart` — `_StepDot` uses `Colors.white` for both the checkmark icon color and the step-number text color (2 occurrences)
  - `lib/features/auth/presentation/screens/driver_onboarding_screen.dart` — `CircularProgressIndicator(color: Colors.white)`
  - `lib/features/auth/presentation/screens/beneficiary_onboarding_screen.dart` — `CircularProgressIndicator(color: Colors.white)`
- **Rule violated:** No hardcoded colors — always use `cs.*` or `ac.*`
- **Detail:** `Colors.white` is a Material constant that bypasses the app's theming system. In dark mode or with a custom `AppColors` override, the checkmark, step number, and progress spinner will be invisible or incorrect. Because `onboarding_step_indicator.dart` lives in `shared/widgets/`, this violation propagates to every feature that uses it.
- **Required fix:** Replace every `Colors.white` occurrence with the appropriate token. For `_StepDot` text and icon, use `ac.onPrimary` or `cs.onPrimary` (whichever is defined for content placed on the active-step fill color). For `CircularProgressIndicator`, use `cs.onPrimary` or `cs.surface` as appropriate to the button context.

### [BLOCKING] Hardcoded inline TextStyle in shared widget — textTheme not used

- **File:** `lib/shared/widgets/onboarding_step_indicator.dart` — `_StepDot` and `_StepConnector` construct `TextStyle(color: Colors.white, fontWeight: ...)` inline
- **Rule violated:** No hardcoded text styles or font sizes — always use `Theme.of(context).textTheme`
- **Detail:** Inline `TextStyle` construction duplicates type-scale decisions that are owned by the theme and will not respond to accessibility font-scaling or future theme updates. Combining this with a hardcoded `Colors.white` compounds the theming violation.
- **Required fix:** Replace inline `TextStyle(...)` with `Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onPrimary)` (or the appropriate text-theme slot). The `color` override must come from the color system, not a Material constant.

### [BLOCKING] Missing widget tests for all new screens and the new shared widget

- **Files:**
  - `lib/features/auth/presentation/screens/driver_onboarding_screen.dart` — no corresponding test found
  - `lib/features/auth/presentation/screens/beneficiary_onboarding_screen.dart` — no corresponding test found
  - `lib/shared/widgets/onboarding_step_indicator.dart` — no corresponding test found
- **Rule violated:** Every screen must have a widget test
- **Detail:** Three new Dart files were added with no accompanying test files. The shared widget is used across the entire onboarding flow, so regressions in its rendering behavior will be invisible without a golden or widget test.
- **Required fix:** Add `test/widget/auth/driver_onboarding_screen_test.dart`, `test/widget/auth/beneficiary_onboarding_screen_test.dart`, and `test/widget/shared/onboarding_step_indicator_test.dart`. At minimum each screen test must verify: (1) the form renders, (2) the submit button triggers the loading state, and (3) an error state is displayed when the provider emits an error.

### [HIGH] Silent broad catch in role_router_screen — errors swallowed without logging

- **File:** `lib/features/auth/presentation/screens/role_router_screen.dart`
- **Line (approx):** beneficiary branch `catch (_)` block
- **Rule violated:** Architectural concern — error handling design; violates the `AppLogger` convention established in `core/logging/`
- **Detail:** `catch (_)` catches every exception, including programming errors (`TypeError`, `RangeError`, `LateInitializationError`), and silently falls through to navigate to `/onboarding/beneficiary`. This means a bug in the beneficiary profile-loading path will appear to the user as "please complete onboarding" rather than an error, permanently hiding the root cause. The driver branch has a narrower `catch (StateError)` but that is also unlogged.
- **Required fix:** Replace both catch clauses with `catch (e, st) { AppLogger.error('role_router_screen', e, st); }` before the fallback navigation. If `StateError` is the only intended signal for "no profile yet," make that explicit and re-throw everything else. See ADR-0017 for the accepted pattern.

### [HIGH] No role guard on onboarding routes — cross-role navigation possible

- **File:** `lib/app/router.dart`
- **Line (approx.):** `/onboarding/driver` and `/onboarding/beneficiary` route definitions
- **Rule violated:** Route guard completeness; defence-in-depth principle
- **Detail:** Both onboarding routes are gated by authentication (not in `isPublic`) but have no role check. A donor who manually navigates to `/onboarding/driver` will land on the driver onboarding screen, construct a `DriverProfile` object, and attempt to write it to the backend under their uid. Depending on the Firestore rules, this may either succeed (creating a phantom driver profile for a donor uid) or fail silently (spinner stuck). Either outcome is incorrect.
- **Required fix:** Add a `redirect` callback on each onboarding route that reads the current user's role from the auth/profile provider and redirects to `/` (or an error page) if the role does not match. Alternatively, assert the role at the start of each onboarding screen's submit handler and display an error state.

### [HIGH] _loading flag never reset to false on happy path in DriverOnboardingScreen

- **File:** `lib/features/auth/presentation/screens/driver_onboarding_screen.dart`
- **Line (approx.):** submit handler — `setState(() => _loading = true)` with no paired reset before `context.go(...)`
- **Rule violated:** Correctness concern with architectural impact — state machine is incomplete
- **Detail:** If `context.go` is called synchronously after an `await` on a completed future, Flutter's navigator will dispose the widget before the next frame and the missing reset is harmless. However, if `context.go` throws or is no-op'd (e.g., the same route is already active), the screen remains mounted with `_loading = true` and the submit button is permanently disabled. This is a latent UI deadlock.
- **Required fix:** Wrap the success navigation and both error paths in a `finally` block that resets `_loading` to false before calling `setState`, or — better — migrate to a Riverpod `AsyncNotifier` state machine so the loading state is observable and reset is automatic.

### [MEDIUM] Empty-string uid fallback silently produces invalid DriverProfile

- **File:** `lib/features/auth/presentation/screens/driver_onboarding_screen.dart`
- **Line (approx.):** `DriverProfile(uid: authUser?.uid ?? '', ...)`
- **Rule violated:** Correctness; data integrity
- **Detail:** If `authStateProvider` has not yet emitted a user when the form is submitted (e.g., a race between auth stream and form render), the constructed `DriverProfile` carries an empty-string `uid`. This will either write a document at path `/drivers/` (invalid Firestore path) or be rejected by security rules, but the error surface presented to the user is undefined. The presentation layer should never proceed with empty identity.
- **Required fix:** Guard the submit handler: if `authUser?.uid` is null or empty, do not submit — show a `SnackBar` or re-trigger auth. Prefer reading uid from a `ref.read(authStateProvider)` inside the notifier rather than from a nullable widget-level variable.

### [MEDIUM] BeneficiaryOnboardingScreen missing PopScope — inconsistent back-navigation behaviour

- **File:** `lib/features/auth/presentation/screens/beneficiary_onboarding_screen.dart`
- **Rule violated:** UX and architectural consistency across the onboarding flow
- **Detail:** `DriverOnboardingScreen` explicitly sets `PopScope(canPop: false)` to prevent incomplete onboarding from being back-navigated. `BeneficiaryOnboardingScreen` has no such guard, allowing a beneficiary to press Back and return to an earlier screen with an incomplete profile. This asymmetry is likely a copy-paste omission rather than an intentional design difference.
- **Required fix:** Add `PopScope(canPop: false)` as the root widget of `BeneficiaryOnboardingScreen`, matching the driver screen. If the intent is to allow back-navigation for beneficiaries but not drivers, document that decision explicitly and add a comment in the code.

### [LOW] No form field validators on either onboarding screen

- **Files:** `driver_onboarding_screen.dart`, `beneficiary_onboarding_screen.dart`
- **Rule violated:** Not a Clean Architecture rule; correctness concern
- **Detail:** No `validator` callbacks are set on any `TextFormField`. An empty phone number, a blank organisation name, or a zero-length address will be submitted to the backend without client-side rejection, generating invalid domain entities. While backend validation is the authoritative gate, the absence of client-side validators creates poor UX and increases unnecessary backend writes.
- **Required fix:** Add `validator` callbacks to each required `TextFormField` using the project's existing validation utilities, or define a `FormValidators` class in `shared/` if none exists.

### [INFO] Future<void> fire-and-forget in whenData — acceptable but worth noting

- **File:** `lib/features/auth/presentation/screens/role_router_screen.dart`
- **Detail:** `whenData(_routeByRole)` discards the returned `Future<void>`. In Riverpod, `whenData` expects `void Function(T)` so the Future is silently dropped. Navigation side-effects complete asynchronously but errors are still caught inside `_routeByRole`. This is currently safe because all error handling is internal to the method, but it means un-thrown errors (i.e., errors caught and suppressed) will not propagate to the Riverpod error boundary. This is an accepted trade-off if the `AppLogger` fix from the HIGH finding above is applied.
- **Recommendation:** No immediate action required beyond the logging fix. Consider wrapping with `unawaited(_routeByRole(data))` and adding a `// ignore: discarded_futures` comment to make the intent explicit and suppress any future lint warning.

---

## ADR required?

Yes. The decision to perform an async profile-completion check inside a router screen (rather than in a dedicated repository method, a GoRouter redirect, or a separate splash screen) is a non-trivial routing architecture choice with team-wide impact. ADR-0017 has been written at `docs/decisions/0017-async-profile-check-in-role-router.md`.

---

## Checklist

- [x] Layer boundaries — domain entities imported from domain layer only; no Flutter imports in domain
- [x] Package imports — no relative imports observed in new files
- [ ] No hardcoded Colors.* — FAILED (5 occurrences across 3 files)
- [ ] No inline TextStyle outside textTheme — FAILED (2 occurrences in shared widget)
- [ ] No unbounded ListView — not applicable to this diff
- [x] CachedNetworkImage for remote images — not applicable to this diff
- [x] No plaintext secrets — no secrets present
- [ ] Widget tests for every new screen — FAILED (0 of 3 new files have tests)
- [ ] Route guards cover role as well as auth — FAILED (no role guard on onboarding routes)
- [ ] Error handling logs before fallback navigation — FAILED (both catch blocks in role_router_screen are silent)
- [x] ADR written for routing architecture change — written as part of this review (ADR-0017)
