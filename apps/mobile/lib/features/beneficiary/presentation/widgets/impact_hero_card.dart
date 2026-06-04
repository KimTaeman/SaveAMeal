import 'package:flutter/material.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/beneficiary_impact_screen.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class ImpactHeroCard extends StatelessWidget {
  const ImpactHeroCard({required this.impact, super.key});

  final BeneficiaryImpact impact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final progress = (impact.totalMeals / kBeneficiaryYearlyGoalMeals).clamp(
      0.0,
      1.0,
    );

    final caption = impact.totalMeals > 0
        ? '${((impact.totalMeals / kBeneficiaryYearlyGoalMeals) * 100).round()}% of yearly goal'
        : 'Start your journey';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL IMPACT',
            style: textTheme.labelSmall?.copyWith(color: cs.onPrimary),
          ),
          const SizedBox(height: Spacing.xs),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${impact.totalMeals}',
                  style: textTheme.displaySmall?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' Meals',
                  style: textTheme.titleMedium?.copyWith(color: cs.onPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xs),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: cs.onPrimary.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            caption,
            style: textTheme.bodySmall?.copyWith(color: cs.onPrimary),
          ),
        ],
      ),
    );
  }
}
