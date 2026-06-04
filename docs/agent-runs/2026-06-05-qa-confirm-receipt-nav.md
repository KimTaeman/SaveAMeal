# QA Review — feat/confirm-receipt (nav fixes)
Date: 2026-06-05
Reviewer: qa-engineer

## Verdict: CHANGES REQUESTED

## Findings

### [SEV: Blocking] Missing `activeDeliveriesProvider` override in BeneficiaryBottomNav-bearing screen tests

`BeneficiaryBottomNav` is now a `ConsumerWidget` that calls
`ref.watch(activeDeliveriesProvider(uid))` on every build. Every screen test that
renders a `Scaffold` containing `BeneficiaryBottomNav` must therefore override that
provider, otherwise the widget tree hits the real Firestore-backed provider and will
throw or hang in test.

Affected test files (none of them include the override):

- `test/widget/features/beneficiary/beneficiary_impact_screen_test.dart` — the
  router includes `BeneficiaryImpactScreen`, which places
  `BeneficiaryBottomNav(currentIndex: 2)` in its scaffold. None of the 11 test cases
  override `activeDeliveriesProvider`. In CI (no Firebase) the provider will either
  throw `UnimplementedError` from the datasource or hang, causing every test in the
  group to fail.

- `test/widget/features/beneficiary/beneficiary_account_screen_test.dart` — same
  problem. `BeneficiaryAccountScreen` uses `BeneficiaryBottomNav(currentIndex: 3)`.
  None of the 5 tests override `activeDeliveriesProvider`.

- `test/widget/features/beneficiary/beneficiary_org_profile_screen_test.dart` — the
  router delivers `BeneficiaryOrgProfileScreen`; this screen's scaffold contains
  `BeneficiaryBottomNav` whose `uid` will be the empty string produced when
  `authStateProvider` resolves to `_testUser` but
  `activeDeliveriesProvider('')` is not overridden.

- `test/widget/features/beneficiary/beneficiary_personal_information_screen_test.dart`
  — same situation.

- `test/widget/features/beneficiary/beneficiary_order_history_screen_test.dart` — the
  router serves `BeneficiaryOrderHistoryScreen`, which has no `BeneficiaryBottomNav`
  in the current source, but `DeliveryHistoryScreen` (a different screen) does, and
  the test router stub only mounts `BeneficiaryOrderHistoryScreen`, so this one
  escapes — but warrants confirmation.

Fix: add `activeDeliveriesProvider('<uid>').overrideWith((ref) => Stream.value([]))`
to every `ProviderScope` override list in the affected files.

---

### [SEV: Blocking] No widget tests for `BeneficiaryBottomNav` or `RecentDeliveriesSection`

`BeneficiaryBottomNav` has three new, non-trivial branches:
1. auth uid is empty — provider is called with `''` as the key.
2. `activeDeliveriesProvider` is still loading — `asData?.value` is null, falls back to
   `const []`, so Track routes to `/beneficiary/history`.
3. `activeDeliveriesProvider` has a non-empty list — Track routes to
   `/beneficiary/delivery/<batchId>`.

None of these scenarios has a dedicated widget test. The project convention (every
screen must have a widget test; every bug fix ships with a regression test) requires
standalone coverage of the navigation widget.

`RecentDeliveriesSection` has four observable states:
- loading (header visible, `CircularProgressIndicator` shown)
- error / null post-load (entire section collapses to `SizedBox.shrink`)
- empty post-load (entire section collapses)
- data (header + `_DeliveryRow` cards rendered)

The `_DeliveryRow` `onTap` (uses `context.push`) and the `View All` `TextButton`
(uses `context.go`) are untested. No test file exists for either widget.

---

### [SEV: Non-blocking] `context.push` on `_DeliveryRow.onTap` creates a navigation stack issue

`RecentDeliveriesSection._DeliveryRow.onTap` calls
`context.push('/beneficiary/delivery/${delivery.batchId}')` (line 108 of
`recent_deliveries_section.dart`). This section is embedded inside
`DeliveryDetailScreen`, which is itself reachable via a `context.go` from
`BeneficiaryBottomNav` (Track tab). The sequence:

1. User taps Track → `context.go('/beneficiary/delivery/A')` — history replaced.
2. `DeliveryDetailScreen` shows `RecentDeliveriesSection`.
3. User taps a row → `context.push('/beneficiary/delivery/B')` — B is pushed on
   top of A.
4. User presses Back → returns to A (correct).
5. User presses Back again from A → no previous route; they land on whatever was in
   the history stack before step 1.

This is actually acceptable for the "recent delivery row → detail" flow, but it means
`DeliveryDetailScreen` for batch A appears below B in the navigation stack, which
uses memory and can cause a stale `RecentDeliveriesSection` rebuild on A when B pops.
Given that `View All` correctly uses `context.go`, the same pattern should be
evaluated for the row taps. Recommendation: change `_DeliveryRow.onTap` to
`context.go(...)` to keep the stack flat, or document the intentional push-based
breadcrumb behaviour explicitly. Low runtime risk, but a test should verify expected
back-navigation behaviour.

---

### [SEV: Non-blocking] `ExcludeSemantics` on `_DeliveryRow` leading icon without a semantic label on the `ListTile`

In `recent_deliveries_section.dart` lines 84–94, the delivery-status circle icon is
wrapped in `ExcludeSemantics`. The trailing chevron (line 104) is also excluded. The
`ListTile` itself has no `Semantics` ancestor and no `semanticLabel`. Screen readers
will announce the `title` ("Today, 14:30") and `subtitle` ("5 Portions • Donor Name")
content, which is sufficient for orientation, but there is no label communicating that
the item is tappable or what action it performs (e.g. "View delivery from Today,
14:30"). WCAG 2.2 SC 4.1.2 requires that interactive components have a name and role.

Fix: wrap the `Card`/`ListTile` with a `Semantics` widget supplying
`label: 'View delivery from ${_formatRelativeDate(delivery.deliveredAt)}'` and
`button: true`.

---

### [SEV: Non-blocking] `BeneficiaryBottomNav` rebuilds on every Firestore emission — scoping is correct but undocumented

`BeneficiaryBottomNav` is a leaf `ConsumerWidget` called from each screen's
`bottomNavigationBar` slot. Riverpod rebuilds only that widget subtree when
`activeDeliveriesProvider` emits, which is the correct scope. However, every
`NavigationBar` rebuild triggers a full measure/layout/paint cycle for the bar. For
the common case where the list transitions from `[]` to `[item]` the rebuild is
cheap. No unbounded list or heavy computation exists inside `build`. No action
required, but a comment explaining the intentional scoping would help future
contributors.

---

### [SEV: Non-blocking] `onDestinationSelected` override removal — confirmed no logic lost

Reviewed all six screens from which `onDestinationSelected` was removed
(`beneficiary_account_screen`, `beneficiary_dashboard_screen`,
`beneficiary_impact_screen`, `beneficiary_order_history_screen`,
`beneficiary_org_profile_screen`, `beneficiary_personal_information_screen`). In
every case the removed overrides were only re-calling `context.go(...)` for
destination indices 0 and 3 (Home and Account), and silently doing nothing for
indices 1 (Track) and 2 (Impact). The new centralised logic in `BeneficiaryBottomNav`
handles all four destinations correctly. No screen-specific logic was lost.

---

### [SEV: Non-blocking] `_normalise` fix in `firestore_service.dart` — correct but untested at unit level

All three previously-missing `_normalise` call sites in
`watchActiveDeliveriesForBeneficiary` and `watchVolunteerQueue` now normalise
Firestore `Timestamp` values before `BatchModel.fromJson`. The fix is structurally
identical to the already-covered `watchOpenBatches` and `watchBatch` call sites. No
unit test exercises `_normalise` directly or via a mocked `QuerySnapshot`. Adding a
unit test that asserts `BatchModel.fromJson` does not throw when a `Timestamp` field
is present would lock in the regression fix.

---

## Test gaps

| Priority | Scenario | File to create |
|---|---|---|
| P0 | Add `activeDeliveriesProvider` override to every existing beneficiary screen test that renders `BeneficiaryBottomNav` | Modify: `beneficiary_impact_screen_test.dart`, `beneficiary_account_screen_test.dart`, `beneficiary_org_profile_screen_test.dart`, `beneficiary_personal_information_screen_test.dart` |
| P0 | `BeneficiaryBottomNav` — uid empty: Track taps go to `/beneficiary/history` | Create: `test/widget/features/beneficiary/beneficiary_bottom_nav_test.dart` |
| P0 | `BeneficiaryBottomNav` — provider loading: Track taps go to `/beneficiary/history` | Same file as above |
| P0 | `BeneficiaryBottomNav` — deliveries non-empty: Track taps go to `/beneficiary/delivery/<batchId>` | Same file as above |
| P0 | `RecentDeliveriesSection` — loading state: header visible, spinner present | Create: `test/widget/features/beneficiary/recent_deliveries_section_test.dart` |
| P0 | `RecentDeliveriesSection` — empty post-load: section collapses to `SizedBox.shrink` | Same file as above |
| P0 | `RecentDeliveriesSection` — data state: header + N rows rendered | Same file as above |
| P0 | `RecentDeliveriesSection` — `View All` taps navigate with `context.go` (replaces stack) | Same file as above |
| P0 | `RecentDeliveriesSection` — row `onTap` navigates to `/beneficiary/delivery/:batchId` | Same file as above |
| P1 | `DeliveryDetailScreen` — loading state: spinner + `BeneficiaryBottomNav` present | Create: `test/widget/features/beneficiary/delivery_detail_screen_test.dart` |
| P1 | `DeliveryDetailScreen` — null/not-found state: "Delivery not found" text present | Same file as above |
| P1 | `DeliveryDetailScreen` — `delivered` status: `_ConfirmReceiptButton` visible | Same file as above |
| P1 | `DeliveryDetailScreen` — `closed` status: `_ConfirmationBanner` visible | Same file as above |
| P1 | `DeliveryDetailScreen` — `cancelled` status: `_CancellationBanner` visible | Same file as above |
| P1 | `DeliveryHistoryScreen` — loading/error/empty/data states + bottom nav index 1 | Create: `test/widget/features/beneficiary/delivery_history_screen_test.dart` |
| P2 | Unit test for `_normalise` timestamp conversion via `FirestoreService` (mock Firestore) | Create: `test/unit/services/firestore_service_normalise_test.dart` |

## Summary

The navigation fixes are logically correct — the `onDestinationSelected` removal
eliminates dead branches, the `_normalise` back-fill prevents `BatchModel.fromJson`
crashes on Timestamp fields, and the dynamic Track routing in `BeneficiaryBottomNav`
correctly handles the active/inactive delivery cases. However, the upgrade of
`BeneficiaryBottomNav` to a `ConsumerWidget` watching `activeDeliveriesProvider`
introduces a new provider dependency that four existing screen tests do not override,
which will cause those tests to fail in CI where Firestore is unavailable. This is a
blocking issue. Additionally, there are zero tests for the two widgets at the centre
of this PR (`BeneficiaryBottomNav` and `RecentDeliveriesSection`), meaning none of the
three Track-routing branches and none of the four section states are regression-
protected. These P0 gaps must be filled before merge.
