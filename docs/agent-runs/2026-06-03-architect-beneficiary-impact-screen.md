# Architect Review — Beneficiary Impact Screen
**Date:** 2026-06-03
**Reviewer:** architect
**Branch:** feat/beneficiary-impact-screen
**Verdict:** CHANGES REQUESTED

---

## Findings

### [BLOCKING] `cloud_firestore` imported directly in the presentation-layer provider — bypasses `firestoreServiceProvider`

**File:** `apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_impact_provider.dart` line 1 and 13

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
...
BeneficiaryImpactRemoteDatasourceImpl(FirebaseFirestore.instance);
```

This is a layer boundary violation. The presentation layer must not import `cloud_firestore` or instantiate Firebase singletons directly. The project-wide convention, established in every other feature provider, is to obtain `FirebaseFirestore` through `ref.watch(firestoreServiceProvider)` which is defined in `lib/services/service_providers.dart`. Confirmed comparisons:

- `donor_provider.dart` line 19: `DonorRemoteDatasourceImpl(ref.watch(firestoreServiceProvider))`
- `beneficiary_provider.dart` line 19: `IntakeRemoteDatasourceImpl(ref.watch(firestoreServiceProvider))`
- `driver_provider.dart`: same pattern

The spec (tech-specs/0005, section 7) also mandates this: `// Implementation must inject FirebaseFirestore via ref.watch(firestoreServiceProvider)`. The implementation deviates from both the spec and the established codebase pattern.

**Why it matters:** Bypassing `firestoreServiceProvider` makes it impossible to override the Firestore instance in widget tests (you cannot swap `FirebaseFirestore.instance` via Riverpod's `ProviderScope` overrides). All other datasource providers are already testable via `ProviderContainer`; this provider breaks that guarantee.

**Fix:**

1. Remove `import 'package:cloud_firestore/cloud_firestore.dart';` from the provider file.
2. Add `import 'package:saveameal/services/service_providers.dart';`
3. Change the datasource provider body to:
   ```dart
   BeneficiaryImpactRemoteDatasourceImpl(ref.watch(firestoreServiceProvider))
   ```

---

### [NON-BLOCKING] `BeneficiaryImpact` entity imports `FoodCategory` from `donor` domain — cross-feature domain dependency

**File:** `apps/mobile/lib/features/beneficiary/domain/entities/beneficiary_impact.dart` line 4

```dart
import 'package:saveameal/features/donor/domain/entities/food_category.dart';
```

The beneficiary domain entity has a compile-time dependency on the donor feature's domain layer. `FoodCategory` is the data type of the `byCategory` map's key. This creates horizontal coupling between two sibling feature domains: a change to the donor feature's `food_category.dart` (renaming a case, adding a case, moving the file) will silently break the beneficiary domain.

The entity itself is otherwise pure Dart — no Flutter or Firebase imports — so the domain purity rule (no `flutter`/`cloud_firestore` imports) is not violated. The cross-feature coupling is a design smell but does not break the layering invariant as long as `FoodCategory` itself is also pure Dart (confirmed: it is a single-line `enum` with no imports).

The engineer has already identified this in a code comment (`TODO(engineer): FoodCategory lives in the donor domain...`). The spec (section 1) also references this import path, meaning it was explicitly approved as part of the design rather than an accidental deviation.

**Recommended resolution (follow-up, not a merge blocker):** Move `FoodCategory` to `lib/shared/domain/enums/food_category.dart` or `lib/core/domain/food_category.dart` when a second feature beyond donor+beneficiary needs it. The TODO comment correctly states the migration path. An ADR should be written at that time.

**Tradeoff of leaving it as-is:** The coupling is confined to a single import line in one entity. Until `FoodCategory` changes, there is zero runtime risk. The reversal cost of the migration is low (one file move + two import updates).

---

### [NON-BLOCKING] Repository is a thin pass-through with no transformation

**File:** `apps/mobile/lib/features/beneficiary/data/repositories/firestore_beneficiary_impact_repository.dart`

`FirestoreBeneficiaryImpactRepository.watchImpact` delegates to `_datasource.watchImpact` with a single line and performs no mapping, caching, or error transformation. The spec (section 6) explicitly permits this, citing Firestore's built-in local persistence as the offline caching mechanism.

This is acceptable for this feature. The repository layer still serves a purpose: it is the seam that allows the datasource to be swapped (e.g., to a REST datasource) without touching the domain interface or the presentation layer. If the team later adds error normalization, retry logic, or a Hive write-through cache, the repository is the correct place.

**No change required.** Documented here for completeness and to confirm that the thin pass-through was intentional per the spec.

---

### [NON-BLOCKING] `impactMetrics` collection is shared by donor and beneficiary documents with overlapping field names

The donor feature writes `impactMetrics/{donorId}` (fields: `totalKg`, `totalMeals`, `totalCo2e`) and the beneficiary feature now writes `impactMetrics/{beneficiaryId}` (fields: `totalKg`, `totalMeals`, `totalCo2e`, `totalDeliveries`, `byCategory`).

If a user holds both a donor role and a beneficiary role (or if UIDs are ever shared between roles), documents may be misread. Firestore security rules gate reads on `request.auth.uid == docId` (spec section, Firestore schema), and the app assigns one role per user at registration, so collision is unlikely in practice for MVP.

The longer-term risk is that the collection name `impactMetrics` is role-agnostic. A future developer adding, say, driver impact metrics would write a third document type into the same collection with ambiguous semantics.

**Recommended resolution (follow-up):** When the project stabilizes, rename the collection to `beneficiaryImpactMetrics` (and `donorImpactMetrics`) to make the distinction explicit in Firestore and in security rules. For MVP, the current design is acceptable.

---

### [NON-BLOCKING] Spec deviation — `authStateProvider.asData?.value` instead of `valueOrNull`

**File:** `apps/mobile/lib/features/beneficiary/presentation/screens/beneficiary_impact_screen.dart` line 20

The screen uses:
```dart
final user = ref.watch(authStateProvider).asData?.value;
```

The spec (section "Screen layout spec") specifies:
```dart
final user = ref.watch(authStateProvider).valueOrNull;
```

Both expressions produce identical runtime behavior: `valueOrNull` is the Riverpod convenience getter that returns `null` when the `AsyncValue` is loading or error. `asData?.value` is the manual equivalent. The difference is stylistic; `valueOrNull` is the idiomatic Riverpod form and is slightly safer because it is less likely to be confused with `.value` (which throws on error in some Riverpod versions).

**Fix (low priority):** Replace `ref.watch(authStateProvider).asData?.value` with `ref.watch(authStateProvider).valueOrNull` for consistency with the spec and with the project idiom.

---

### [NON-BLOCKING] No widget tests included in this PR

**Convention:** CLAUDE.md states "every screen must have a widget test." The spec (test plan) lists five test files:

- `test/unit/features/beneficiary/beneficiary_impact_model_test.dart`
- `test/unit/features/beneficiary/watch_beneficiary_impact_usecase_test.dart`
- `test/widget/features/beneficiary/beneficiary_impact_screen_test.dart`
- `test/widget/features/beneficiary/impact_hero_card_test.dart`
- `test/widget/features/beneficiary/impact_category_row_test.dart`

None of these files appear in the branch's untracked file list. The same finding was raised for the donor-impact-screen PR. Tests must be delivered before this branch is merged to main.

---

### [INFORMATIONAL] `ImpactCategoryRow` trailing text has a hardcoded `color: cs.primary` not present in the spec

**File:** `apps/mobile/lib/features/beneficiary/presentation/widgets/impact_category_row.dart` line 61

```dart
style: textTheme.bodyMedium?.copyWith(
  fontWeight: FontWeight.bold,
  color: cs.primary,  // ← not in spec
),
```

The spec widget contract for `ImpactCategoryRow` specifies the trailing text style as `textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)` with no explicit color override. Applying `cs.primary` to the percentage text is not a convention violation (it uses a theme token), but it is an undocumented deviation from the approved spec. The color will match the leading icon color which may or may not be the intended design. This does not block merge but should be confirmed with the design system owner.

---

## Summary

The implementation is structurally correct for six of the seven checks. Domain files (`beneficiary_impact.dart`, `beneficiary_impact_repository.dart`, `watch_beneficiary_impact_usecase.dart`) contain zero Flutter or Firebase imports — domain purity is maintained. The data layer correctly confines all `cloud_firestore` usage. Presentation files do not import `data/` layer types or Firebase directly, with one exception: `beneficiary_impact_provider.dart` imports `cloud_firestore` and uses `FirebaseFirestore.instance` directly, bypassing `firestoreServiceProvider`. This is the single BLOCKING finding; it violates the project-wide dependency injection pattern, breaks test overridability, and deviates from the approved spec.

**Resolution required before merge:**

1. (BLOCKING) Remove `import 'package:cloud_firestore/cloud_firestore.dart'` from `beneficiary_impact_provider.dart` and replace `FirebaseFirestore.instance` with `ref.watch(firestoreServiceProvider)`.
2. (NON-BLOCKING but required by CLAUDE.md) Deliver the five test files listed in the spec test plan.

All other findings are advisory and may be addressed in follow-up issues.
