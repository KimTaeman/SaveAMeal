import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class RecentDeliveriesSection extends ConsumerWidget {
  const RecentDeliveriesSection({super.key, required this.beneficiaryId});

  final String beneficiaryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentDeliveriesProvider(beneficiaryId));

    return async.when(
      loading: () => const SizedBox.shrink(),
      // ignore: avoid_types_on_closure_parameters
      error: (Object err, StackTrace st) => const SizedBox.shrink(),
      data: (deliveries) {
        if (deliveries.isEmpty) return const SizedBox.shrink();

        final textTheme = Theme.of(context).textTheme;
        final cs = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Deliveries',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/beneficiary/history'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(
                      'View All',
                      style: textTheme.labelMedium?.copyWith(color: cs.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
            ...deliveries.map((d) => _DeliveryRow(delivery: d)),
          ],
        );
      },
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({required this.delivery});

  final RecentDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: cs.surfaceContainerLow,
        child: ListTile(
          leading: ExcludeSemantics(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ac.success,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: ac.onSuccess, size: 20),
            ),
          ),
          title: Text(
            _formatRelativeDate(delivery.deliveredAt),
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${delivery.portions} Portions'
            '${delivery.donorName != null ? ' • ${delivery.donorName}' : ''}',
            style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          trailing: ExcludeSemantics(
            child: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ),
          onTap: () {},
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: 4,
          ),
        ),
      ),
    );
  }
}

String _formatRelativeDate(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(date).inDays;
  final time =
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  if (diff == 0) return 'Today, $time';
  if (diff == 1) return 'Yesterday, $time';
  if (diff < 7) return '$diff days ago, $time';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}, $time';
}
