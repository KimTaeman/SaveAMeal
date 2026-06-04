# QA Review — feat/beneficiary-profile
Date: 2026-06-04
Reviewer: qa-engineer

## Verdict: CHANGES REQUESTED

---

## Checklist

| # | Item | Result | Evidence |
|---|------|--------|----------|
| 1 | Widget test exists for all 4 new screens | PASS | All 4 files present under `test/widget/features/beneficiary/` |
| 2 | Loading state tested in every screen | WARN | AccountScreen: PASS (line 126-151). OrgProfile: test exists but asserts only `Scaffold` present, not `CircularProgressIndicator` (line 148-175). PersonalInfo: screen has no early-return loading guard, so no test needed — PASS by design. OrderHistory: screen has a uid-empty `CircularProgressIndicator` guard (screen line 31-36) but no test for it — FAIL |
| 3 | Empty state for OrderHistory tested (`'No deliveries yet'`) | PASS | `beneficiary_order_history_screen_test.dart` line 115-121 |
| 4 | Form validation error tested (`'Name is required'`) | PASS | `beneficiary_personal_information_screen_test.dart` line 174-211 |
| 5 | Navigation tap tested in AccountScreen | PASS | `beneficiary_account_screen_test.dart` line 206-239 |
| 6 | OrderHistoryCard `'Delivered'` and `'In Transit'` badges both tested | PASS | Lines 132-146 of order history test |
| 7 | Load More button shown when `hasMore: true`, hidden when `hasMore: false` | PASS | Lines 148-171 of order history test |
| 8 | `flutter analyze` zero issues | PASS | `No issues found! (ran in 2.2s)` |
| 9a | `Switch` has semantic label | FAIL | `beneficiary_account_screen.dart:248` — Switch has no `Semantics` wrapper, no `semanticLabel`. It is inside a `ListTile` with a title of `'Push Notifications'`, which provides implicit context but not an explicit label on the control itself. WCAG 2.2 AA requires interactive controls to have an accessible name. |
| 9b | `ElevatedButton` / `OutlinedButton` have labels | PASS | Both carry visible text children (`'Save'`, `'Save Profile Changes'`, `'Load More History'`, `'Log Out'`) which Flutter maps to semantic labels automatically |
| 9c | Photo upload `GestureDetector` has `Semantics` wrapper | FAIL | `beneficiary_personal_information_screen.dart:240` — bare `GestureDetector` with no `Semantics` wrapper and no `tooltip`. Screen readers will announce this as a tap target with no label |
| 10 | No raw `Color()` or raw spacing doubles in test files | PASS | No matches found in `test/widget/features/beneficiary/` |
| 11 | No unbounded `ListView` | PASS | `beneficiary_order_history_screen.dart` uses `CustomScrollView` + `SliverList` with `SliverChildBuilderDelegate` / `SliverChildListDelegate`. No bare `ListView(children: [...])` found anywhere in the feature |

---

## Findings

### [BLOCKING] Missing loading-state test for OrderHistoryScreen uid-empty guard

`beneficiary_order_history_screen.dart` lines 31-36 return a `CircularProgressIndicator` scaffold when `uid` is empty (auth not yet resolved). No test exercises this branch. Every screen with a loading guard must have a corresponding test per the QA test matrix.

Fix: add a test to `beneficiary_order_history_screen_test.dart` that overrides `authStateProvider` with an empty stream (`Stream.empty()` or a controller with no events), pumps once, and asserts `find.byType(CircularProgressIndicator)`.

### [BLOCKING] OrgProfileScreen loading-state test does not assert `CircularProgressIndicator`

`beneficiary_org_profile_screen_test.dart` lines 148-175 — the test is named `'shows CircularProgressIndicator when profile is loading'` but the assertion is `expect(find.byType(Scaffold), findsWidgets)`. This is a vacuous test; it passes even if the screen shows a fully-rendered form instead of a spinner.

Root cause: `BeneficiaryOrgProfileScreen` has no early-return loading guard — it renders the form immediately and populates controllers lazily. The test comment acknowledges this (`// The screen renders the form even during loading`). Either:
  (a) add a loading guard to the screen (return `CircularProgressIndicator` when `profileAsync.isLoading && !profileAsync.hasValue`) and update the test to assert it, or
  (b) rename the test to `'renders scaffold without error while profile is loading'` and update the test description so it is not misleading.

Option (b) is lower risk and does not change production behaviour.

### [BLOCKING] Photo upload `GestureDetector` missing `Semantics` label

`beneficiary_personal_information_screen.dart:240` — the profile-photo tap target is a raw `GestureDetector` with no `Semantics` wrapper. Screen readers (TalkBack / VoiceOver) will not announce any label for this interactive element, failing WCAG 2.2 Success Criterion 4.1.2 (Name, Role, Value).

Fix:
```dart
Semantics(
  label: 'Upload profile photo',
  button: true,
  child: GestureDetector(
    onTap: _uploadingPhoto ? null : _pickImage,
    ...
  ),
)
```
A regression test asserting `find.bySemanticsLabel('Upload profile photo')` should accompany the fix.

### [WARNING] `Switch` widget missing explicit semantic label

`beneficiary_account_screen.dart:248` — the `Switch` is inside a `ListTile` whose `title` is `'Push Notifications'`. Flutter's `ListTile` does propagate the title text as a merged semantic label when the tile itself is tappable, but a `Switch` in the `trailing` slot gets its own separate semantic node. Without an explicit `semanticLabel` on the switch, some assistive technology configurations will announce only "Switch, on" with no associated label.

Fix: add `semanticLabel: 'Push notifications'` to the `Switch` constructor:
```dart
Switch(
  value: _notificationsEnabled,
  onChanged: (v) => setState(() => _notificationsEnabled = v),
  activeThumbColor: cs.primary,
  semanticLabel: 'Push notifications',
),
```

### [WARNING] `pumpAndSettle` called without `Duration` argument

All `pumpAndSettle()` calls in the new test files use the unbounded form (no `Duration`). The QA rules require `pumpAndSettle(Duration)`. Flaky tests are more likely in CI when async timers run beyond Flutter's default 100 ms budget.

Fix: change each call to a bounded form, for example:
```dart
await tester.pumpAndSettle(const Duration(seconds: 3));
```

### [INFO] OrgProfileScreen `updateOrgProfile` not asserted via fake repository

The `'Save button is enabled and calls updateOrgProfile on tap'` test in `beneficiary_org_profile_screen_test.dart` (lines 222-273) validates that the button is present and `onPressed` is non-null, but does not assert `fakeRepo.updateOrgProfileCalled == true`. The comment explains this is because `DropdownButtonFormField.initialValue` is not picked up by `FormField._value` without an interactive selection, which causes validation to fail and the usecase to not be called.

This is a known Flutter limitation. The intent is noted but the test does not fully verify the repository call path. Consider adding a helper that programmatically selects the dropdown value, or test the usecase directly at the unit level.

---

## Summary

`flutter analyze` passes with zero issues and `dart format` produces no diff. All 23 widget tests pass. The four new screens are covered. The test matrix has three blocking issues: (1) the OrgProfile loading-state test name is misleading and the assertion is vacuous because the screen has no loading guard — either fix the screen or rename the test; (2) the OrderHistory uid-empty `CircularProgressIndicator` branch has no test; (3) the photo upload `GestureDetector` has no `Semantics` label and fails WCAG 2.2 AA SC 4.1.2. Additionally, the `Switch` in AccountScreen is missing a `semanticLabel` (warning) and all `pumpAndSettle` calls are unbounded (warning). No raw `ListView`, no raw `Color()`, and no hardcoded spacing doubles were found in test files. Performance posture is clean.
