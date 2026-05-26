import 'package:flutter/material.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class HowPausingWorksSection extends StatelessWidget {
  const HowPausingWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW STATUS PAUSING WORKS',
          style: textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: Spacing.md),
        const _HowItem(
          number: 1,
          text:
              'Setting status to Full removes your pin from the donor map immediately.',
        ),
        const _HowItem(
          number: 2,
          text: 'Active deliveries will not be canceled to avoid food waste.',
        ),
        const _HowItem(
          number: 3,
          text: 'Toggle back to Accepting whenever your storage is ready.',
        ),
      ],
    );
  }
}

class _HowItem extends StatelessWidget {
  const _HowItem({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: ac.success,
            child: Text(
              '$number',
              style: textTheme.labelSmall?.copyWith(
                color: ac.onSuccess,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(child: Text(text, style: textTheme.bodySmall)),
        ],
      ),
    );
  }
}
