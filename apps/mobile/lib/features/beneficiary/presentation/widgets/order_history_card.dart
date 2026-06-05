import 'package:flutter/material.dart';
import 'package:saveameal/features/beneficiary/domain/entities/order_history_entry.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:saveameal/shared/utils/batch_id_formatter.dart';

class OrderHistoryCard extends StatelessWidget {
  const OrderHistoryCard({required this.entry, super.key});

  final OrderHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final isDelivered =
        entry.status == OrderHistoryEntryStatus.delivered ||
        entry.status == OrderHistoryEntryStatus.closed;
    final accentColor = isDelivered ? ac.success : ac.warning;

    return Card(
      color: cs.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: Spacing.xs, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.sm + Spacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDate(entry.date),
                          style: textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        isDelivered
                            ? _deliveredBadge(ac, textTheme)
                            : _inTransitBadge(ac, textTheme),
                      ],
                    ),
                    SizedBox(height: Spacing.xs),
                    Text(
                      'Order ${formatBatchId(entry.id)}',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(height: Spacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(Spacing.sm),
                      ),
                      padding: const EdgeInsets.all(Spacing.sm + Spacing.xs),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _iconBgColor(entry.foodCategory, cs, ac),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _iconData(entry.foodCategory),
                              size: 18,
                              color: _iconColor(entry.foodCategory, cs, ac),
                            ),
                          ),
                          SizedBox(width: Spacing.sm + Spacing.xs),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.itemDescription,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'From: ${entry.donorName}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _monthAbbr = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${_monthAbbr[d.month - 1]} ${d.day}, ${d.year}';
  }

  static Widget _deliveredBadge(AppColors ac, TextTheme t) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: Spacing.sm + Spacing.xs,
      vertical: Spacing.xs,
    ),
    decoration: BoxDecoration(
      color: ac.success.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 14, color: ac.success),
        const SizedBox(width: Spacing.xs),
        Text(
          'Delivered',
          style: t.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: ac.success,
          ),
        ),
      ],
    ),
  );

  static Widget _inTransitBadge(AppColors ac, TextTheme t) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: Spacing.sm + Spacing.xs,
      vertical: Spacing.xs,
    ),
    decoration: BoxDecoration(
      color: ac.warning.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_shipping_outlined, size: 14, color: ac.warning),
        const SizedBox(width: Spacing.xs),
        Text(
          'In Transit',
          style: t.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: ac.warning,
          ),
        ),
      ],
    ),
  );

  static Color _iconBgColor(String? cat, ColorScheme cs, AppColors ac) =>
      cat == 'baked_goods'
      ? ac.warning.withValues(alpha: 0.15)
      : cs.primaryContainer;

  static Color _iconColor(String? cat, ColorScheme cs, AppColors ac) =>
      cat == 'baked_goods' ? ac.warning : ac.success;

  static IconData _iconData(String? cat) {
    switch (cat) {
      case 'hot_meals':
        return Icons.lunch_dining;
      case 'baked_goods':
        return Icons.bakery_dining;
      case 'produce':
        return Icons.eco;
      default:
        return Icons.fastfood;
    }
  }
}
