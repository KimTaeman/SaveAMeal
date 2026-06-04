import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/features/donor/presentation/widgets/donor_bottom_nav.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:saveameal/shared/widgets/donor_brand_title.dart';

class DonorImpactScreen extends ConsumerWidget {
  const DonorImpactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.asData?.value;
    final uid = user?.uid ?? '';

    final metricsAsync = ref.watch(donorMetricsProvider(uid));
    final batchesAsync = ref.watch(activeBatchesProvider(uid));

    final metrics = metricsAsync.asData?.value ?? DonorMetrics.empty;
    final batches = batchesAsync.asData?.value ?? <Batch>[];

    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;

    final categoryMap = _buildCategoryMap(batches);
    final categoryTotal = categoryMap.values.fold<int>(0, (sum, v) => sum + v);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: Spacing.md,
        title: const DonorBrandTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      bottomNavigationBar: DonorBottomNav(
        currentIndex: 1,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/donor');
            case 1:
              context.go('/donor/impact');
            case 2:
              context.go('/donor/batches');
            case 3:
              context.go('/donor/account');
          }
        },
      ),
      body: ListView.builder(
        itemCount: 1,
        itemBuilder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Section 1: Total Impact card ──────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Spacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [ac.brand, ac.brandLight],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'TOTAL IMPACT',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: Spacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${metrics.totalMeals}',
                            style: textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Meals',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Spacing.md),
                      Center(
                        child: SizedBox(
                          width: 220,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 0.0,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.3,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: Spacing.xs),
                      Text(
                        '0% of yearly goal',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Spacing.md),

                // ── Section 2: Stat cards ─────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.eco,
                        label: 'CO2 Diverted',
                        value: metrics.totalCO2e.toStringAsFixed(1),
                        unit: 'Tons',
                      ),
                    ),
                    SizedBox(width: Spacing.sm),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.delete_outline,
                        label: 'Waste Saved',
                        value: metrics.totalKg.toStringAsFixed(1),
                        unit: 'kg',
                      ),
                    ),
                  ],
                ),

                SizedBox(height: Spacing.md),

                // ── Section 3: By Category ────────────────────────────────
                Text(
                  'By Category',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Spacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: _kAllCategories.asMap().entries.map((entry) {
                      final i = entry.key;
                      final cat = entry.value;
                      final count = categoryMap[_categoryLabel(cat)] ?? 0;
                      final pct = categoryTotal == 0
                          ? 0
                          : ((count / categoryTotal) * 100).round();
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _iconForCategory(cat),
                                  color: ac.brand,
                                  size: 20,
                                ),
                                SizedBox(width: Spacing.sm),
                                Expanded(
                                  child: Text(
                                    _categoryLabel(cat),
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  '$pct%',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: ac.brand,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (i < _kAllCategories.length - 1)
                            const Divider(height: 1, indent: Spacing.md),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                SizedBox(height: Spacing.md),
              ],
            ),
          );
        },
      ),
    );
  }

  static const _kAllCategories = FoodCategory.values;

  static Map<String, int> _buildCategoryMap(List<Batch> batches) {
    final counts = <String, int>{};
    for (final batch in batches) {
      for (final item in batch.items) {
        final cat = _categoryLabel(item.category);
        counts[cat] = (counts[cat] ?? 0) + 1;
      }
    }
    return counts;
  }

  static String _categoryLabel(FoodCategory category) => switch (category) {
    FoodCategory.bakery => 'Bakery',
    FoodCategory.produce => 'Fruits & Veggies',
    FoodCategory.dairy => 'Dairy',
    FoodCategory.meat => 'Meat',
    FoodCategory.beverages => 'Beverages',
    FoodCategory.other => 'Other',
  };

  static IconData _iconForCategory(FoodCategory category) => switch (category) {
    FoodCategory.bakery => Icons.bakery_dining,
    FoodCategory.produce => Icons.energy_savings_leaf,
    FoodCategory.dairy => Icons.water_drop,
    FoodCategory.meat => Icons.set_meal,
    FoodCategory.beverages => Icons.local_drink,
    FoodCategory.other => Icons.category,
  };
}

// ── _StatCard ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border(top: BorderSide(color: ac.brand, width: 3)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: ac.brand, size: 24),
          SizedBox(height: Spacing.xs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Spacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ac.brand,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ac.brand,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
