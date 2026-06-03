---
title: "0005: Beneficiary Impact Screen"
description: "Full layer spec for the beneficiary impact screen: real-time Firestore stream of impactMetrics/{beneficiaryId}, BeneficiaryImpact entity with per-category breakdown, one use case, one Riverpod StreamProvider, ImpactHeroCard/ImpactMetricTile/ImpactCategoryRow widgets, Cloud Function extension to write beneficiary-scoped metrics, and router wiring."
---

# SPEC-0005: Beneficiary Impact Screen

**Status:** APPROVED
**Author:** architect
**Date:** 2026-06-03
**Proposal:** [PROP-0005](../tech-proposals/0005-beneficiary-impact-screen.md)
**Approved by:** ALORA

---

## Overview

This spec delivers the Beneficiary Impact screen — a dedicated route (`/beneficiary/impact`) that surfaces a beneficiary's all-time nourishment metrics: total meals received, total kg of food, total CO2e prevented, total deliveries, and a per-category kg breakdown. Metrics are streamed in real time from a new `impactMetrics/{beneficiaryId}` Firestore document, written by an extended `onDeliveryComplete` Cloud Function. The Domain layer is pure Dart; Firebase imports are confined to the Data layer. Offline degradation uses Firestore's built-in local cache, with an error banner shown if the cache is cold and the device is offline.

---

## Architecture

```mermaid
flowchart LR
    subgraph Presentation
        P1[beneficiary_impact_provider.dart\nbeneficiaryImpactProvider]
        P2[BeneficiaryImpactScreen]
        W1[ImpactHeroCard]
        W2[ImpactMetricTile]
        W3[ImpactCategoryRow]
    end
    subgraph Domain
        UC[WatchBeneficiaryImpactUsecase]
        R[BeneficiaryImpactRepository\ninterface]
        E[BeneficiaryImpact entity]
    end
    subgraph Data
        RI[FirestoreBeneficiaryImpactRepository]
        DS[BeneficiaryImpactRemoteDatasourceImpl\nFirestore snapshots]
        M[BeneficiaryImpactModel\nfromFirestore / toEntity]
    end
    subgraph CloudFunctions["Cloud Functions"]
        CF1[onDeliveryComplete.ts]
        CF2[computations.ts]
    end

    P2 --> P1
    P2 --> W1
    P2 --> W2
    P2 --> W3
    P1 --> UC
    UC --> R
    R --> E
    RI --> DS
    DS --> M
    RI -.implements.-> R
    CF1 --> CF2
    CF1 -->|writes impactMetrics/{beneficiaryId}| DS
```

**Layer constraints:**

- `domain/` — zero Flutter or Firebase imports. Pure Dart only. `BeneficiaryImpactRepository`, `WatchBeneficiaryImpactUsecase`, and `BeneficiaryImpact` live here.
- `data/` — may import `cloud_firestore`. Must not be imported by `presentation/` directly.
- `presentation/` — may import `flutter`, `flutter_riverpod`, `go_router`, and domain entities/use cases. Must not import `data/` or Firestore directly.

---

## File map

| Action     | Path                                                                                                  | Responsibility                                                                                                   |
| ---------- | ----------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Modify** | `functions/src/computations.ts`                                                                       | Add `category?: string` to `BatchItem`; add `computeByCategory(items)` function                                  |
| **Modify** | `functions/src/onDeliveryComplete.ts`                                                                 | Add beneficiary-scoped `impactMetrics/{beneficiaryId}` write inside the `if (beneficiaryId)` block               |
| **Create** | `apps/mobile/lib/features/beneficiary/domain/entities/beneficiary_impact.dart`                        | `BeneficiaryImpact` pure Dart entity with `byCategory` map and `empty` constant                                  |
| **Create** | `apps/mobile/lib/features/beneficiary/domain/repositories/beneficiary_impact_repository.dart`         | Abstract `BeneficiaryImpactRepository` interface with `watchImpact`                                              |
| **Create** | `apps/mobile/lib/features/beneficiary/domain/usecases/watch_beneficiary_impact_usecase.dart`          | `WatchBeneficiaryImpactUsecase` — delegates `call(beneficiaryId)` to the repository                              |
| **Create** | `apps/mobile/lib/features/beneficiary/data/models/beneficiary_impact_model.dart`                      | `BeneficiaryImpactModel` — `fromFirestore` factory, field-safe defaults, `toEntity()` mapper                     |
| **Create** | `apps/mobile/lib/features/beneficiary/data/datasources/beneficiary_impact_remote_datasource.dart`     | Abstract `BeneficiaryImpactRemoteDatasource` interface and `Impl` class streaming Firestore snapshots            |
| **Create** | `apps/mobile/lib/features/beneficiary/data/repositories/firestore_beneficiary_impact_repository.dart` | `FirestoreBeneficiaryImpactRepository` — implements interface, maps model to entity                              |
| **Create** | `apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_impact_provider.dart`        | Four `@riverpod` providers: datasource, repository, use case, stream                                             |
| **Create** | `apps/mobile/lib/features/beneficiary/presentation/screens/beneficiary_impact_screen.dart`            | `BeneficiaryImpactScreen` — full `ConsumerWidget`, `kBeneficiaryYearlyGoalMeals` constant, bottom nav at index 2 |
| **Create** | `apps/mobile/lib/features/beneficiary/presentation/widgets/impact_hero_card.dart`                     | `ImpactHeroCard` — green hero card with meal count, progress bar, and yearly-goal caption                        |
| **Create** | `apps/mobile/lib/features/beneficiary/presentation/widgets/impact_metric_tile.dart`                   | `ImpactMetricTile` — single metric card (icon + label + value) used for CO2 Diverted and Waste Saved             |
| **Create** | `apps/mobile/lib/features/beneficiary/presentation/widgets/impact_category_row.dart`                  | `ImpactCategoryRow` — one row in the By Category list (icon + name + percentage)                                 |
| **Modify** | `apps/mobile/lib/app/router.dart`                                                                     | Add `GoRoute(path: 'impact')` sub-route under `/beneficiary` pointing to `BeneficiaryImpactScreen`               |
| **Modify** | `apps/mobile/lib/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart`         | Wire `case 2` in the `NavigationBar.onDestinationSelected` to `context.go('/beneficiary/impact')`                |

---

## API contracts

All interfaces below are the exact Dart signatures the engineer must implement. No pseudocode.

### 1. Domain entity — `BeneficiaryImpact`

```dart
// apps/mobile/lib/features/beneficiary/domain/entities/beneficiary_impact.dart
// Pure Dart entity — no Flutter or backend imports.
import 'package:saveameal/features/beneficiary/domain/entities/food_category.dart';

class BeneficiaryImpact {
  const BeneficiaryImpact({
    required this.totalMeals,
    required this.totalKg,
    required this.totalCo2e,
    required this.totalDeliveries,
    required this.byCategory,
  });

  final int totalMeals;
  final double totalKg;
  final double totalCo2e;
  final int totalDeliveries;
  final Map<FoodCategory, double> byCategory; // category → kg

  static const empty = BeneficiaryImpact(
    totalMeals: 0,
    totalKg: 0,
    totalCo2e: 0,
    totalDeliveries: 0,
    byCategory: {},
  );
}
```

`BeneficiaryImpact.empty` is the fallback value when the `impactMetrics/{beneficiaryId}` document does not yet exist (beneficiary has no completed deliveries). It ensures the screen always renders a zero state rather than a loading spinner that never resolves.

---

### 2. `BeneficiaryImpactRepository` abstract interface

```dart
// apps/mobile/lib/features/beneficiary/domain/repositories/beneficiary_impact_repository.dart
// Pure Dart interface — no Flutter or backend imports.
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';

abstract class BeneficiaryImpactRepository {
  Stream<BeneficiaryImpact> watchImpact(String beneficiaryId);
}
```

---

### 3. `WatchBeneficiaryImpactUsecase`

```dart
// apps/mobile/lib/features/beneficiary/domain/usecases/watch_beneficiary_impact_usecase.dart
// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_impact_repository.dart';

class WatchBeneficiaryImpactUsecase {
  const WatchBeneficiaryImpactUsecase(this._repository);

  final BeneficiaryImpactRepository _repository;

  Stream<BeneficiaryImpact> call(String beneficiaryId) =>
      _repository.watchImpact(beneficiaryId);
}
```

---

### 4. `BeneficiaryImpactRemoteDatasource`

```dart
// apps/mobile/lib/features/beneficiary/data/datasources/beneficiary_impact_remote_datasource.dart
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';

abstract class BeneficiaryImpactRemoteDatasource {
  /// Firestore snapshots() on impactMetrics/{beneficiaryId}.
  /// Emits BeneficiaryImpact.empty when the document does not exist.
  Stream<BeneficiaryImpact> watchImpact(String beneficiaryId);
}

class BeneficiaryImpactRemoteDatasourceImpl
    implements BeneficiaryImpactRemoteDatasource {
  const BeneficiaryImpactRemoteDatasourceImpl(this._firestore);

  final dynamic _firestore; // concrete type: FirebaseFirestore

  @override
  Stream<BeneficiaryImpact> watchImpact(String beneficiaryId) {
    // Implementation:
    // _firestore.collection('impactMetrics').doc(beneficiaryId).snapshots()
    // .map((ds) => ds.exists
    //     ? BeneficiaryImpactModel.fromFirestore(ds.data()!).toEntity()
    //     : BeneficiaryImpact.empty)
    throw UnimplementedError();
  }
}
```

---

### 5. `BeneficiaryImpactModel`

Firestore document schema at `impactMetrics/{beneficiaryId}`:

```json
{
  "totalKg": 3100.0,
  "totalMeals": 8420,
  "totalCo2e": 3100.0,
  "totalDeliveries": 47,
  "byCategory": {
    "bakery": 465.0,
    "produce": 930.0,
    "dairy": 0.0,
    "meat": 0.0,
    "beverages": 0.0,
    "other": 1705.0
  }
}
```

All fields default to zero when absent. The `byCategory` field may be missing entirely on legacy documents.

```dart
// apps/mobile/lib/features/beneficiary/data/models/beneficiary_impact_model.dart
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/features/beneficiary/domain/entities/food_category.dart';

class BeneficiaryImpactModel {
  const BeneficiaryImpactModel({
    required this.totalMeals,
    required this.totalKg,
    required this.totalCo2e,
    required this.totalDeliveries,
    required this.byCategory,
  });

  final int totalMeals;
  final double totalKg;
  final double totalCo2e;
  final int totalDeliveries;
  final Map<String, double> byCategory; // raw string keys from Firestore

  factory BeneficiaryImpactModel.fromFirestore(Map<String, dynamic> data) {
    final rawCategory =
        (data['byCategory'] as Map<String, dynamic>?) ?? const {};
    final byCategory = <String, double>{
      for (final entry in rawCategory.entries)
        entry.key: (entry.value as num? ?? 0).toDouble(),
    };
    return BeneficiaryImpactModel(
      totalMeals: (data['totalMeals'] as num? ?? 0).toInt(),
      totalKg: (data['totalKg'] as num? ?? 0).toDouble(),
      totalCo2e: (data['totalCo2e'] as num? ?? 0).toDouble(),
      totalDeliveries: (data['totalDeliveries'] as num? ?? 0).toInt(),
      byCategory: byCategory,
    );
  }

  BeneficiaryImpact toEntity() {
    final mapped = <FoodCategory, double>{};
    for (final entry in byCategory.entries) {
      try {
        final category = FoodCategory.values.byName(entry.key);
        mapped[category] = entry.value;
      } on ArgumentError {
        // Unknown category key — skip silently.
      }
    }
    return BeneficiaryImpact(
      totalMeals: totalMeals,
      totalKg: totalKg,
      totalCo2e: totalCo2e,
      totalDeliveries: totalDeliveries,
      byCategory: mapped,
    );
  }
}
```

---

### 6. `FirestoreBeneficiaryImpactRepository`

```dart
// apps/mobile/lib/features/beneficiary/data/repositories/firestore_beneficiary_impact_repository.dart
import 'package:saveameal/features/beneficiary/data/datasources/beneficiary_impact_remote_datasource.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_impact_repository.dart';

class FirestoreBeneficiaryImpactRepository
    implements BeneficiaryImpactRepository {
  const FirestoreBeneficiaryImpactRepository(this._datasource);

  final BeneficiaryImpactRemoteDatasource _datasource;

  @override
  Stream<BeneficiaryImpact> watchImpact(String beneficiaryId) =>
      _datasource.watchImpact(beneficiaryId);
}
```

The repository is a thin pass-through for this spec because Firestore's local persistence handles offline caching natively. There is no Hive write-through layer for beneficiary impact metrics — the Firestore SDK caches the document automatically.

---

### 7. Riverpod providers

All providers use `@riverpod` codegen. File: `apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_impact_provider.dart`.

```dart
// apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_impact_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/beneficiary/data/datasources/beneficiary_impact_remote_datasource.dart';
import 'package:saveameal/features/beneficiary/data/repositories/firestore_beneficiary_impact_repository.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_impact_repository.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/watch_beneficiary_impact_usecase.dart';
import 'package:saveameal/services/service_providers.dart';

part 'beneficiary_impact_provider.g.dart';

@riverpod
BeneficiaryImpactRemoteDatasource beneficiaryImpactRemoteDatasource(Ref ref);
// Implementation must inject FirebaseFirestore via ref.watch(firestoreServiceProvider).

@riverpod
BeneficiaryImpactRepository beneficiaryImpactRepository(Ref ref) =>
    FirestoreBeneficiaryImpactRepository(
      ref.watch(beneficiaryImpactRemoteDatasourceProvider),
    );

@riverpod
WatchBeneficiaryImpactUsecase watchBeneficiaryImpactUsecase(Ref ref) =>
    WatchBeneficiaryImpactUsecase(
      ref.watch(beneficiaryImpactRepositoryProvider),
    );

@riverpod
Stream<BeneficiaryImpact> beneficiaryImpact(Ref ref, String beneficiaryId) =>
    ref.watch(watchBeneficiaryImpactUsecaseProvider).call(beneficiaryId);
```

`beneficiaryImpactProvider` is a family provider (takes `beneficiaryId`). Riverpod codegen generates `beneficiaryImpactProvider(beneficiaryId)` from the function signature.

---

### 8. Router changes

Add a `'impact'` sub-route under the existing `/beneficiary` `GoRoute`:

```dart
// apps/mobile/lib/app/router.dart — add inside the existing /beneficiary routes list:
GoRoute(
  path: 'impact',
  // full path: /beneficiary/impact
  builder: (context, state) => const BeneficiaryImpactScreen(),
),
```

---

### 9. `BeneficiaryDashboardScreen` navigation wiring

In `beneficiary_dashboard_screen.dart`, add `case 2` to the existing `NavigationBar.onDestinationSelected` switch:

```dart
case 2: context.go('/beneficiary/impact');
```

---

### 10. Yearly goal constant

```dart
// Defined at the top of beneficiary_impact_screen.dart, outside the class.
const int kBeneficiaryYearlyGoalMeals = 10000;
```

The `ImpactHeroCard` uses this constant for the `LinearProgressIndicator` value computation: `(impact.totalMeals / kBeneficiaryYearlyGoalMeals).clamp(0.0, 1.0)`.

---

### 11. TypeScript — `computations.ts` changes

```typescript
// Extended interface — add optional category field
export interface BatchItem {
  weightKg: number;
  category?: string;
}

// New function — returns only categories with kg > 0
export function computeByCategory(items: BatchItem[]): Record<string, number>;
// Implementation: group items by category, sum weightKg per group.
// Items with no category or an empty string are bucketed under 'other'.
// Categories with a total of 0 kg are omitted from the returned object.
```

---

### 12. TypeScript — `onDeliveryComplete.ts` changes

Inside the `if (beneficiaryId)` block, after computing `totalKg`, `totalMeals`, `totalCo2e`, and `byCategory`:

```typescript
// Step 1: compute per-category breakdown
const categoryBreakdown = computeByCategory(items);

// Step 2: build dot-notation update object for nested map fields
const categoryUpdate: Record<string, FirebaseFirestore.FieldValue> = {};
for (const [cat, kg] of Object.entries(categoryBreakdown)) {
  categoryUpdate[`byCategory.${cat}`] = FieldValue.increment(kg);
}

// Step 3: push atomic update to ops array
ops.push(
  db
    .collection("impactMetrics")
    .doc(beneficiaryId)
    .set(
      {
        totalKg: FieldValue.increment(totalKg),
        totalMeals: FieldValue.increment(totalMeals),
        totalCo2e: FieldValue.increment(totalCo2e),
        totalDeliveries: FieldValue.increment(1),
      },
      { merge: true },
    ),
);
ops.push(
  db.collection("impactMetrics").doc(beneficiaryId).update(categoryUpdate),
);
```

**Important:** `FieldValue.increment` inside a `set(..., { merge: true })` call does not work for nested map fields because Firestore treats the entire nested object as a replace. The `byCategory.*` fields must be written via a separate `update()` call using dot-notation keys (e.g. `byCategory.bakery`). The two `ops` pushes shown above reflect this constraint. Both operations are included in the same batched write so they are atomic.

---

## Firestore document schema

Document path: `impactMetrics/{beneficiaryId}`

| Field              | Type     | Written by           | Notes                                                                            |
| ------------------ | -------- | -------------------- | -------------------------------------------------------------------------------- |
| `totalKg`          | `number` | `onDeliveryComplete` | Cumulative kg across all deliveries; `FieldValue.increment`                      |
| `totalMeals`       | `number` | `onDeliveryComplete` | Cumulative meal count; `FieldValue.increment`                                    |
| `totalCo2e`        | `number` | `onDeliveryComplete` | Cumulative CO2e in kg; `FieldValue.increment`                                    |
| `totalDeliveries`  | `number` | `onDeliveryComplete` | Incremented by 1 per completed delivery                                          |
| `byCategory.<key>` | `number` | `onDeliveryComplete` | Per-category kg via dot-notation `update()`; key is a `FoodCategory` name string |

All fields default to `0` when absent (new document created by first `set(..., { merge: true })`). The `byCategory` map is absent on documents written before this spec is deployed; the Flutter client's `fromFirestore` factory defaults it to an empty map.

Security rules: `impactMetrics/{docId}` reads are allowed where `docId == request.auth.uid` — no rule change required.

---

## Screen layout spec

`BeneficiaryImpactScreen` is a `ConsumerWidget`. It reads the current user from `authStateProvider`:

```dart
final user = ref.watch(authStateProvider).valueOrNull;
final beneficiaryId = user?.uid ?? '';
```

If `beneficiaryId` is empty the widget renders `CircularProgressIndicator` centered (auth not yet resolved).

The widget watches `beneficiaryImpactProvider(beneficiaryId)` and renders one of three UI states:

**Loading state** — `impactAsync` is `AsyncLoading` with no prior data: render `CircularProgressIndicator` centered inside the `Scaffold` body.

**Error state** — `impactAsync.hasError` is true: render the full loaded layout using `BeneficiaryImpact.empty` as the fallback value, with the offline banner shown at the top of the scroll body. Banner copy: `"Could not load impact data. Check your connection."` Same `_OfflineBanner` pattern as `BeneficiaryHomeScreen`.

**Loaded state:**

```
Scaffold
  appBar: AppBar matching BeneficiaryHomeScreen header
    (pin icon + "SaveAMeal" title on left, notification bell on right)
  body: SafeArea
    SingleChildScrollView
      Column
        ─── _OfflineBanner (visible only when impactAsync.hasError)
        ─── ImpactHeroCard(impact: impact)
        ─── SizedBox(height: Spacing.md)
        ─── Row(children: [
              Expanded(child: ImpactMetricTile(
                icon: Icons.eco_outlined,
                label: 'CO2 Diverted',
                value: '${(impact.totalCo2e / 1000).toStringAsFixed(1)} Tons',
              )),
              SizedBox(width: Spacing.sm),
              Expanded(child: ImpactMetricTile(
                icon: Icons.scale_outlined,
                label: 'Waste Saved',
                value: '${impact.totalKg.toStringAsFixed(0)} kg',
              )),
            ])
        ─── SizedBox(height: Spacing.md)
        ─── Padding(horizontal: Spacing.md,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('By Category', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(onPressed: null, child: Text('Details')),
                ],
              ))
        ─── (hidden when all byCategory values are zero)
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: filteredCategories.length,
              itemBuilder: (_, i) => ImpactCategoryRow(
                category: filteredCategories[i].key,
                kg: filteredCategories[i].value,
                totalKg: impact.totalKg,
              ),
            )
        ─── SizedBox(height: Spacing.sm)
        ─── Card(
              color: cs.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(Spacing.md),
                child: Text(
                  'Impact data reflects your all-time nourishment history on SaveAMeal.',
                  style: textTheme.bodySmall,
                ),
              ))
        ─── SizedBox(height: Spacing.xl)
  bottomNavigationBar: NavigationBar(
    selectedIndex: 2,
    onDestinationSelected: (index) { /* same switch as BeneficiaryHomeScreen */ },
    destinations: [/* same 4 destinations as BeneficiaryHomeScreen */],
  )
```

The `filteredCategories` list is derived client-side: `impact.byCategory.entries.where((e) => e.value > 0).toList()`.

**`ImpactHeroCard` widget contract:**

- Accepts `BeneficiaryImpact impact` as a named required parameter.
- `Container` with `decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(16))`, full-width, `margin: EdgeInsets.symmetric(horizontal: Spacing.md)`, `padding: EdgeInsets.all(Spacing.lg)`.
- `Text('TOTAL IMPACT', style: textTheme.labelSmall?.copyWith(color: cs.onPrimary))`.
- `RichText`: meal count `"${impact.totalMeals.toString()}"` in `textTheme.displaySmall?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.bold)` followed by `" Meals"` in `textTheme.titleMedium?.copyWith(color: cs.onPrimary)`.
- When `impact == BeneficiaryImpact.empty`: display `"0 Meals"` and the progress-bar caption reads `"Start your journey"`.
- `LinearProgressIndicator` with `value: (impact.totalMeals / kBeneficiaryYearlyGoalMeals).clamp(0.0, 1.0)`, `backgroundColor: cs.onPrimary.withOpacity(0.3)`, `valueColor: AlwaysStoppedAnimation(cs.onPrimary)`.
- Caption below the bar: when `impact.totalMeals > 0`, show `"${((impact.totalMeals / kBeneficiaryYearlyGoalMeals) * 100).round()}% of yearly goal"` in `textTheme.bodySmall?.copyWith(color: cs.onPrimary)`. When `impact.totalMeals == 0`, show `"Start your journey"`.
- No hardcoded colors.

**`ImpactMetricTile` widget contract:**

- Accepts `IconData icon`, `String label`, `String value` as named required parameters.
- `Card(color: cs.surface)` with `BorderRadius.circular(12)`, `margin: EdgeInsets.zero`, `padding: EdgeInsets.all(Spacing.md)`.
- `Column(crossAxisAlignment: CrossAxisAlignment.start)`: `Icon(icon, color: cs.primary, size: 24)`, `SizedBox(height: Spacing.xs)`, `Text(label, style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant))`, `Text(value, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))`.
- No hardcoded colors.

**`ImpactCategoryRow` widget contract:**

- Accepts `FoodCategory category`, `double kg`, `double totalKg` as named required parameters.
- `ListTile` with `leading: Icon(_categoryIcon(category), color: cs.primary)`, `title: Text(_categoryDisplayName(category), style: textTheme.bodyMedium)`, `trailing: Text('${(kg / totalKg * 100).round()}%', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))`.
- `_categoryDisplayName` mapping: `bakery → 'Bakery'`, `produce → 'Produce'`, `dairy → 'Dairy'`, `meat → 'Meat'`, `beverages → 'Beverages'`, `other → 'Other'`.
- `_categoryIcon` mapping: `bakery → Icons.bakery_dining_outlined`, `produce → Icons.eco_outlined`, `dairy → Icons.water_drop_outlined`, `meat → Icons.set_meal_outlined`, `beverages → Icons.local_drink_outlined`, `other → Icons.category_outlined`.
- Percentage is computed from `(kg / totalKg * 100).round()`. When `totalKg == 0`, the row must not be rendered (caller filters before building).
- No hardcoded colors.

---

## Test plan

| Test file                                                                   | Covers                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Type   |
| --------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| `test/unit/features/beneficiary/beneficiary_impact_model_test.dart`         | `BeneficiaryImpactModel.fromFirestore` with full document (all fields present), partial document (some fields absent, expect zero defaults), empty map (no `byCategory` key), unknown category key (skipped silently); `toEntity()` maps string keys to `FoodCategory` values correctly                                                                                                                                                                              | Unit   |
| `test/unit/features/beneficiary/watch_beneficiary_impact_usecase_test.dart` | `WatchBeneficiaryImpactUsecase.call` delegates to `BeneficiaryImpactRepository.watchImpact`; mock repository stream emits a known `BeneficiaryImpact` and the use case re-emits it unchanged                                                                                                                                                                                                                                                                         | Unit   |
| `test/widget/features/beneficiary/beneficiary_impact_screen_test.dart`      | Loading state: `CircularProgressIndicator` shown when provider is `AsyncLoading`; loaded state: `ImpactHeroCard` present and meal count displayed, two `ImpactMetricTile` widgets rendered, category rows shown for non-zero categories; zero state: `"0 Meals"` and `"Start your journey"` copy shown, By Category section hidden; error state: offline banner with correct copy shown, `BeneficiaryImpact.empty` rendered below; bottom nav `selectedIndex` is `2` | Widget |
| `test/widget/features/beneficiary/impact_hero_card_test.dart`               | Progress bar `value` equals `totalMeals / kBeneficiaryYearlyGoalMeals` clamped to `[0, 1]`; percentage caption matches `round()` computation; zero state shows `"Start your journey"` instead of percentage copy                                                                                                                                                                                                                                                     | Widget |
| `test/widget/features/beneficiary/impact_category_row_test.dart`            | Row renders correct display name and icon for each `FoodCategory`; percentage text is `(kg / totalKg * 100).round()%`; rows with `kg == 0` are not rendered (caller responsibility — test the screen's filter logic)                                                                                                                                                                                                                                                 | Widget |

---

## Out of scope

- Per-delivery history list.
- Back-fill of historical `impactMetrics` data for deliveries completed before this spec is deployed.
- Yearly goal configuration per beneficiary — `kBeneficiaryYearlyGoalMeals` is a compile-time constant (`10000`) for MVP.
- Date range filtering — all counters are all-time totals.
- "Details" `TextButton` navigation from the By Category section header — `onPressed: null` for MVP.
- Offline mutations — beneficiary impact is read-only on the client.
- Hive write-through cache for beneficiary impact — Firestore's built-in persistence is sufficient.
- Cloud Function deployment — the user owns the deployment pipeline.

---

## Open questions

All proposal open questions are resolved:

- [x] **Back-fill**: not required for MVP — only deliveries completed after deployment are counted.
- [x] **Metric set**: `totalMeals`, `totalKg`, `totalCo2e`, `totalDeliveries`, `byCategory` map confirmed.
- [x] **Empty state**: zero-filled with `"Start your journey"` caption in the hero card.
- [x] **Dedicated screen**: confirmed by Figma — `/beneficiary/impact` sub-route.
- [x] **Deployment**: user owns the Cloud Function deployment.

---

## Acceptance criteria

These criteria are the pass/fail gate for the QA engineer before the spec status moves to `IMPLEMENTED`.

**Real-time updates**

- When `onDeliveryComplete` fires for a beneficiary, the Impact screen's meal count and category breakdown update within ten seconds of the Cloud Function completing, without the beneficiary manually refreshing.

**Offline / cached data**

- With network connectivity disabled after at least one successful Firestore emission, the Impact screen renders the last-known metrics from Firestore's local cache within two seconds of navigating to the screen.
- The offline error banner is visible when the device has never loaded the document and goes offline.
- No unhandled exception or blank screen is shown in any offline scenario.
- When connectivity is restored, the screen silently re-syncs with Firestore without user action.

**Zero state**

- A beneficiary with no completed deliveries sees `"0 Meals"`, a progress bar at `0%`, `"Start your journey"` caption, and the By Category section is hidden.

**Metrics correctness**

- CO2 Diverted tile displays `(totalCo2e / 1000).toStringAsFixed(1) Tons`.
- Waste Saved tile displays `totalKg.toStringAsFixed(0) kg`.
- Category row percentage equals `(categoryKg / totalKg * 100).round()%`.
- Only categories with `kg > 0` are shown in the By Category list.
- Progress bar `value` equals `(totalMeals / 10000).clamp(0.0, 1.0)`.

**Navigation**

- Tapping the Impact destination (index 2) in the bottom nav on `BeneficiaryHomeScreen` navigates to `/beneficiary/impact`.
- Back navigation from `/beneficiary/impact` returns to `/beneficiary`.

**Architecture constraints**

- `flutter analyze` produces zero errors or warnings on the beneficiary feature slice.
- Domain layer files (`domain/entities/`, `domain/repositories/`, `domain/usecases/`) contain zero `import 'package:flutter` or `import 'package:cloud_firestore` statements.
- `BeneficiaryImpactScreen` contains no direct `FirebaseFirestore` calls.
- By Category list uses `ListView.builder` with `shrinkWrap: true` and `NeverScrollableScrollPhysics` inside `SingleChildScrollView` — no unbounded `ListView`.
