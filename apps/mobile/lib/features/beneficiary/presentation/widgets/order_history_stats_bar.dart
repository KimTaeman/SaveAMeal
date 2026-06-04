import 'package:flutter/material.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/delivery_history_notifier.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

/// Two-tile stats bar: Total Meals (sum of portions) and Deliveries (count).
/// Stats are computed from loaded pages only; shows a disclaimer when hasMore == true.
class OrderHistoryStatsBar extends StatelessWidget {
  const OrderHistoryStatsBar({super.key, required this.state});

  final DeliveryHistoryState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final totalMeals = state.items
        .fold(0, (sum, d) => sum + d.portions)
        .toString();
    final totalDeliveries = state.items.length.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.restaurant_menu_outlined,
                    value: totalMeals,
                    label: 'Total Meals',
                    accentColor: ac.brand,
                    underlineColor: ac.brand,
                  ),
                ),
                const VerticalDivider(thickness: 1),
                Expanded(
                  child: _StatTile(
                    icon: Icons.local_shipping_outlined,
                    value: totalDeliveries,
                    label: 'Deliveries',
                    accentColor: ac.brand,
                    underlineColor: ac.brand,
                  ),
                ),
              ],
            ),
          ),
          if (state.hasMore) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              '*Showing totals for loaded deliveries',
              style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.accentColor,
    required this.underlineColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accentColor;
  final Color underlineColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: accentColor),
        const SizedBox(height: Spacing.xs),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: Spacing.xs),
        // Coloured underline tab indicator per Figma
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: underlineColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
