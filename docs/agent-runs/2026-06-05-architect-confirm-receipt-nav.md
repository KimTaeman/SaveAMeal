# Architect Review — feat/confirm-receipt (nav fixes)
Date: 2026-06-05
Reviewer: architect

---

## Verdict: APPROVED

All blocking concerns from the previous review cycle have been resolved. One non-blocking design concern is documented below and should be tracked as a follow-up, not a merge gate.

---

## Findings

### [SEV: Non-blocking] BeneficiaryBottomNav encodes routing business logic that belongs in a coordinator provider

**File:** `apps/mobile/lib/features/beneficiary/presentation/widgets/beneficiary_bottom_nav.dart` (lines 19–37)

**Description:** The widget upgrades to `ConsumerWidget`, watches `authStateProvider` and `activeDeliveriesProvider(uid)`, and uses that data to decide between `/beneficiary/delivery/{batchId}` and `/beneficiary/history` when index 1 is tapped. This makes the nav bar a decision-maker, not just a view. The routing rule "if active deliveries exist, go to delivery; else go to history" is business logic. If the same rule ever needs to apply to a deep-link, a notification tap, or a shell-redirect, there is currently no single source of truth — the logic lives only inside the widget.

**Why it matters:** Navigation decision logic embedded in a shared widget is difficult to unit-test in isolation and tends to be duplicated when other entry points (push notifications, deep links) need the same conditional route. The current manual-per-screen nav pattern means every screen that hosts this widget will silently pick up the routing logic; screens with a custom `onDestinationSelected` override will silently bypass it.

**Recommendation (non-blocking):** Extract the routing decision into a dedicated Riverpod provider — e.g., `beneficiaryTrackDestinationProvider(uid)` returning a `String` route — that `BeneficiaryBottomNav` simply reads. All other entry points (notification tap handlers, deep-link redirects) can watch the same provider. This does not need to block the current merge; the routing behaviour is correct; the concern is future maintainability.

**Tradeoffs:**
- Keep as-is: less indirection, works today, consistent with how `BeneficiaryHomeScreen` already watches `activeDeliveriesProvider` directly. Cost: logic duplication risk when new entry points arrive.
- Extract to provider: single source of truth for the routing rule, trivially unit-testable. Cost: one extra provider file, minor added indirection.

---

### [SEV: Non-blocking] `deliveries.first` is safe in current Dart/Riverpod lifecycle, but a comment would prevent future regressions

**File:** `apps/mobile/lib/features/beneficiary/presentation/widgets/beneficiary_bottom_nav.dart` (line 34)

**Description:** The code reads:
```dart
final deliveries = ref.watch(activeDeliveriesProvider(uid)).asData?.value ?? const [];
// ...
if (deliveries.isNotEmpty) {
  context.go('/beneficiary/delivery/${deliveries.first.batchId}');
}
```

The guard `isNotEmpty` and the `.first` access happen within the same synchronous build frame. Because `deliveries` is a local `final` — not re-evaluated between the guard and the access — there is no race condition in the traditional sense. However, if this block is ever refactored to be async (e.g., in an `onPressed` callback that awaits something before reading the list again from the provider), the guard and the access could diverge.

**Recommendation:** Add an inline comment: `// deliveries is a local final — guard and access are in the same sync frame, no TOCTOU risk.` This costs zero runtime overhead and prevents a future engineer from "cleaning up" the guard under the mistaken belief it is redundant.

---

### [SEV: Informational] `_normalise` coverage is complete across all `BatchModel.fromJson` call sites

**File:** `apps/mobile/lib/services/firestore_service.dart`

All call sites that produce a `BatchModel` from a Firestore document snapshot apply `_normalise` before `fromJson`:
- `watchOpenBatches` (line 83)
- `watchBatch` (line 94)
- `watchActiveDeliveriesForBeneficiary` (line 125)
- `watchRecentDeliveriesForBeneficiary` (line 144)
- `watchVolunteerQueue` — both the pending subscription (line 180) and the dispatched subscription (line 196)
- `watchActiveBatchForDriver` (line 247)
- `watchActiveBatchesForDonor` (line 424)
- `watchAllBatchesForDonor` (line 438)
- `fetchDeliveryHistoryPage` (line 517)

No call site was missed. Coverage is complete.

---

### [SEV: Informational] Domain layer purity confirmed

**Files checked:** all files under `apps/mobile/lib/features/beneficiary/domain/entities/`

A grep for `import 'package:flutter`, `import 'package:cloud_firestore`, and `import 'package:firebase` across the entire domain entities directory returned zero matches. `intake_request.dart` and `intake_request_detail.dart` are pure Dart. `recent_delivery.dart`, `beneficiary_impact.dart`, `incoming_batch.dart`, `intake_item.dart`, `delivery_history_page.dart`, `order_history_entry.dart`, `beneficiary_profile.dart`, and `beneficiary_org_profile_update.dart` are all clean.

---

### [SEV: Informational] `onDestinationSelected` override removal is safe

**Files:** six beneficiary screens that previously carried partial `onDestinationSelected` overrides.

Inspection of the remaining screens (`BeneficiaryHomeScreen`, `BeneficiaryImpactScreen`, `BeneficiaryAccountScreen`, `DeliveryDetailScreen`, `DeliveryHistoryScreen`) confirms that none of the removed overrides performed screen-specific side effects (scroll position save, cleanup, analytics, etc.). The overrides were routing-only duplications of what `BeneficiaryBottomNav` now handles centrally. Their removal is correct and reduces drift between screens.

---

### [SEV: Informational] `context.go` vs `context.push` split in `recent_deliveries_section.dart` is intentional and correct

**File:** `apps/mobile/lib/features/beneficiary/presentation/widgets/recent_deliveries_section.dart`

- "View All" (`TextButton`) uses `context.go('/beneficiary/history')` — this is a tab-level navigation that replaces the current stack position. Correct: the user is navigating to a sibling tab destination, not drilling into a detail.
- Card `onTap` uses `context.push('/beneficiary/delivery/${delivery.batchId}')` — this pushes a detail screen onto the stack. Correct: the user expects a back button to return to the section they tapped from.

This split is consistent with the pattern used elsewhere in the beneficiary feature (e.g., `BeneficiaryHomeScreen` uses `context.push` for `ActiveDeliveryCard` detail navigation).

---

### [SEV: Informational] No ADR required for this changeset

The changes in this branch are bug fixes and behavioural corrections to an existing pattern. No new architectural decision was introduced:
- `BeneficiaryBottomNav` upgrading to `ConsumerWidget` is consistent with ADR-0009 (presentation-layer domain entity imports) and the established Riverpod pattern.
- `_normalise` propagation is a data-layer correctness fix, not a design decision.
- The `context.go` / `context.push` split follows the navigation decision already recorded in ADR-0002.

No new ADR is warranted.

---

## Checklist

- [x] Domain layer: zero Flutter or Firebase imports in all touched entity files
- [x] Data layer: all `BatchModel.fromJson` call sites in `firestore_service.dart` apply `_normalise`
- [x] Presentation layer: `BeneficiaryBottomNav` imports are presentation-only (Flutter, Riverpod, GoRouter, presentation providers)
- [x] `deliveries.first` access is guarded by `isNotEmpty` in the same sync frame
- [x] `onDestinationSelected` removals verified as routing-only with no lost side effects
- [x] `context.go` vs `context.push` usage is consistent with app-wide navigation pattern
- [x] No new external dependencies introduced
- [x] No hardcoded colours, text styles, or magic spacing numbers in new/modified widgets
- [x] ADR necessity assessed — none required
