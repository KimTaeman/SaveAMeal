import 'package:flutter/material.dart';
  import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
  import 'package:saveameal/shared/theme/app_colors.dart';
  import 'package:saveameal/shared/theme/spacing.dart';

class ActiveDeliveryCard extends StatelessWidget {
  const ActiveDeliveryCard({
    super.key,
    required this.request,
    required this.onViewDetails,
    this.onTrack,
  });

  final IntakeRequest request;
  final VoidCallback onViewDetails;
  final VoidCallback? onTrack;

    @override
    Widget build(BuildContext context) {
      final cs = Theme.of(context).colorScheme;
      final ac = Theme.of(context).extension<AppColors>()!;
      final textTheme = Theme.of(context).textTheme;

      final isDispatched = request.status == IntakeStatus.dispatched;
      final badgeLabel = isDispatched ? 'IN TRANSIT' : 'AWAITING VOLUNTEER';

      final badgeColor = isDispatched
          ? ac.warning.withValues(alpha: 0.2)
          : cs.surfaceContainerHigh;
      final badgeTextColor = isDispatched ? ac.warning : cs.onSurfaceVariant;

      final volunteerInitials = (request.volunteerName ?? 'V')
          .split(' ')
          .take(2)
          .map((e) => e.isNotEmpty ? e[0] : '')
          .join()
          .toUpperCase();

      return Card(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: cs.surface,
        elevation: 0,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: ac.success,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
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
                          GestureDetector(
                            onTap: onViewDetails,
                            child: Text(
                              'View Details >',
                              style: textTheme.labelMedium?.copyWith(
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: ac.success.withValues(alpha: 0.15),
                            child: Text(
                              volunteerInitials,
                              style: textTheme.labelMedium?.copyWith(
                                color: ac.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${request.volunteerName ?? 'A volunteer'} is on the way',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${request.portions} portions • ${request.mealDescription}'
                                  '${request.estimatedArrivalMinutes != null ? ' • ETA ${request.estimatedArrivalMinutes} min' : ''}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (onTrack != null && request.volunteerId != null) ...[
                        const SizedBox(height: Spacing.sm),
                        GestureDetector(
                          onTap: onTrack,
                          child: Text(
                            'Track Delivery →',
                            style: textTheme.labelMedium?.copyWith(
                              color: cs.secondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }