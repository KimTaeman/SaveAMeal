import 'package:flutter/material.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class ActiveDeliveryCard extends StatelessWidget {
  const ActiveDeliveryCard({
    super.key,
    required this.request,
    required this.onViewDetails,
  });

  final IntakeRequest request;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final isDispatched = request.status == IntakeStatus.dispatched;

    final badgeColor = isDispatched ? ac.warning : cs.surfaceContainerHigh;
    final badgeTextColor = isDispatched ? ac.onWarning : cs.onSurfaceVariant;
    final badgeLabel = isDispatched ? 'IN TRANSIT' : 'AWAITING VOLUNTEER';

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cs.surfaceContainerLow,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    badgeLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: badgeTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (request.estimatedArrivalMinutes != null)
                  Text(
                    'ETA ${request.estimatedArrivalMinutes} min',
                    style: textTheme.labelMedium,
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              '${request.volunteerName ?? 'A volunteer'} is on the way',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${request.portions} portions • ${request.mealDescription}',
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: Spacing.sm),
            GestureDetector(
              onTap: onViewDetails,
              child: Text(
                'View Details →',
                style: textTheme.labelMedium?.copyWith(color: cs.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
