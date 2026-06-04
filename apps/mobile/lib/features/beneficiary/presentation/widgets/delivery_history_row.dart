import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

/// Single card row in the delivery history list.
/// Tapping navigates to /beneficiary/delivery/:batchId.
class DeliveryHistoryRow extends StatelessWidget {
  const DeliveryHistoryRow({super.key, required this.delivery});

  final RecentDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final formattedDate = DateFormat(
      'MMM dd, yyyy',
    ).format(delivery.deliveredAt);
    final orderRef =
        '#${delivery.batchId.substring(0, delivery.batchId.length.clamp(0, 8)).toUpperCase()}';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: cs.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              context.push('/beneficiary/delivery/${delivery.batchId}'),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent border — always ac.success for delivered/closed
                Container(width: 4, color: ac.success),
                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: date + status chip
                              Row(
                                children: [
                                  Text(
                                    formattedDate,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: Spacing.sm),
                                  _StatusChip(acColors: ac),
                                ],
                              ),
                              const SizedBox(height: Spacing.xs),
                              // Order reference number
                              Text(
                                orderRef,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: Spacing.xs),
                              // Portions + category
                              Row(
                                children: [
                                  _CategoryIcon(
                                    category: delivery.category,
                                    acColors: ac,
                                  ),
                                  const SizedBox(width: Spacing.xs),
                                  Text(
                                    '${delivery.portions} ${_categoryLabel(delivery.category)}',
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: Spacing.xs),
                              // Donor name
                              Text(
                                'From: ${delivery.donorName ?? "Unknown donor"}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Trailing chevron
                        Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Green "Delivered" pill chip — always shown for delivered/closed status.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.acColors});

  final AppColors acColors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: acColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.check_circle_outline,
              size: 12,
              color: acColors.success,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'Delivered',
            style: textTheme.labelSmall?.copyWith(color: acColors.success),
          ),
        ],
      ),
    );
  }
}

/// Circular category icon sized 28, mapped from the category string.
class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category, required this.acColors});

  final String? category;
  final AppColors acColors;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor(category, acColors);
    final label = _categoryLabel(category);

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  static (IconData, Color) _iconAndColor(String? category, AppColors ac) {
    if (category == null) return (Icons.inventory_2_outlined, ac.brand);

    final lower = category.toLowerCase();
    if (lower.contains('meal') || lower.contains('hot')) {
      return (Icons.restaurant, ac.success);
    }
    if (lower.contains('baked') || lower.contains('bread')) {
      return (Icons.bakery_dining, ac.warning);
    }
    if (lower.contains('produce') ||
        lower.contains('fresh') ||
        lower.contains('vegetable')) {
      return (Icons.eco, ac.success);
    }
    return (Icons.inventory_2_outlined, ac.brand);
  }
}

/// Capitalises the first letter of each word; falls back to "Portions".
String _categoryLabel(String? category) {
  if (category == null || category.isEmpty) return 'Portions';
  return category
      .split(' ')
      .map(
        (word) =>
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
      )
      .join(' ');
}
