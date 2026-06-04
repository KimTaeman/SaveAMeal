import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_impact_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/beneficiary_bottom_nav.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/impact_category_row.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/impact_hero_card.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/impact_metric_tile.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

const int kBeneficiaryYearlyGoalMeals = 10000;

class BeneficiaryImpactScreen extends ConsumerWidget {
  const BeneficiaryImpactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    final beneficiaryId = user?.uid ?? '';

    if (beneficiaryId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final impactAsync = ref.watch(beneficiaryImpactProvider(beneficiaryId));

    if (impactAsync.isLoading && !impactAsync.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasError = impactAsync.hasError;
    final impact = impactAsync.value ?? BeneficiaryImpact.empty;

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final filteredCategories = impact.byCategory.entries
        .where((e) => e.value > 0)
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.location_on, color: cs.primary),
            const SizedBox(width: Spacing.xs),
            Text('SaveAMeal', style: textTheme.titleLarge),
          ],
        ),
        actions: const [
          IconButton(icon: Icon(Icons.notifications_outlined), onPressed: null),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasError) const _OfflineBanner(),
              const SizedBox(height: Spacing.sm),
              ImpactHeroCard(impact: impact),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: ImpactMetricTile(
                      icon: Icons.eco_outlined,
                      label: 'CO2 Diverted',
                      value:
                          '${(impact.totalCo2e / 1000).toStringAsFixed(1)} Tons',
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: ImpactMetricTile(
                      icon: Icons.scale_outlined,
                      label: 'Waste Saved',
                      value: '${impact.totalKg.toStringAsFixed(0)} kg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'By Category',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(onPressed: null, child: const Text('Details')),
                ],
              ),
              const SizedBox(height: Spacing.xs),
              if (filteredCategories.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredCategories.length,
                  itemBuilder: (_, i) => ImpactCategoryRow(
                    category: filteredCategories[i].key,
                    kg: filteredCategories[i].value,
                    totalKg: impact.totalKg,
                  ),
                ),
              const SizedBox(height: Spacing.sm),
              Card(
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Text(
                    'Impact data reflects your all-time nourishment history on SaveAMeal.',
                    style: textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BeneficiaryBottomNav(
        currentIndex: 2,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/beneficiary');
            case 1:
              context.go('/beneficiary/history');
            case 2:
              break; // already here
            case 3:
              context.go('/beneficiary/account');
          }
        },
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      color: ac.warning,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: Text(
        'Could not load impact data. Check your connection.',
        style: textTheme.bodySmall?.copyWith(color: ac.onWarning),
        textAlign: TextAlign.center,
      ),
    );
  }
}
