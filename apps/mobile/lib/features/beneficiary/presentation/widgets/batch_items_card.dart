import 'package:flutter/material.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class BatchItemsCard extends StatelessWidget {
  const BatchItemsCard({super.key, required this.detail});

  final IntakeRequestDetail detail;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Origin chip
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    border: Border.all(color: cs.outline),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: 4,
                  ),
                  child: Text(
                    'Origin: ${detail.donorName ?? 'Unknown'}',
                    style: textTheme.labelMedium,
                  ),
                ),
                // Portions pill
                Container(
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: 4,
                  ),
                  child: Text(
                    '${detail.portions} Portions',
                    style: textTheme.labelMedium?.copyWith(color: cs.onPrimary),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: detail.items.length,
            itemBuilder: (context, index) {
              final item = detail.items[index];
              return ListTile(
                leading: Icon(Icons.restaurant, color: cs.onSurfaceVariant),
                title: Text(item.name, style: textTheme.bodyMedium),
                trailing: Text(
                  '${item.weightKg.toStringAsFixed(1)} kg',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                dense: true,
              );
            },
          ),
        ],
      ),
    );
  }
}
