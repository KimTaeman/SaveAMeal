import 'package:flutter/material.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

/// A read-only card displaying a beneficiary's organisation profile.
/// Shows name, org-type badge, address, mission statement and distance.
/// Highlighted with [ColorScheme.primaryContainer] when [isSelected].
class BeneficiaryDestinationCard extends StatelessWidget {
  const BeneficiaryDestinationCard({
    super.key,
    required this.beneficiary,
    required this.isSelected,
    required this.onTap,
    this.distanceKm,
  });

  final Beneficiary beneficiary;
  final double? distanceKm;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    // ignore: unused_local_variable
    final ac = Theme.of(context).extension<AppColors>()!;

    return Card(
      color: isSelected ? cs.primaryContainer : cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.sm),
        side: isSelected
            ? BorderSide(color: cs.primary, width: 2)
            : BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Spacing.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row: org name + distance badge ────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      beneficiary.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? cs.onPrimaryContainer
                            : cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  _DistanceBadge(
                    distanceKm: distanceKm,
                    isSelected: isSelected,
                  ),
                ],
              ),

              // ── Org-type badge ────────────────────────────────────────────
              if (beneficiary.orgType != null) ...[
                const SizedBox(height: Spacing.xs),
                _OrgTypeBadge(orgType: beneficiary.orgType!),
              ],

              // ── Address row ───────────────────────────────────────────────
              if (beneficiary.address != null) ...[
                const SizedBox(height: Spacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: Spacing.md,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Expanded(
                      child: Text(
                        beneficiary.address!,
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // ── Mission statement ─────────────────────────────────────────
              if (beneficiary.missionStatement != null) ...[
                const SizedBox(height: Spacing.xs),
                Text(
                  beneficiary.missionStatement!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({required this.distanceKm, required this.isSelected});

  final double? distanceKm;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final label = distanceKm != null
        ? '${distanceKm!.toStringAsFixed(1)} km'
        : 'Distance unavailable';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primary.withValues(alpha: 0.15)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Spacing.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.near_me_outlined,
            size: Spacing.md,
            color: isSelected ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgTypeBadge extends StatelessWidget {
  const _OrgTypeBadge({required this.orgType});

  final String orgType;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(Spacing.xs),
      ),
      child: Text(
        orgType,
        style: textTheme.labelSmall?.copyWith(color: cs.onSecondaryContainer),
      ),
    );
  }
}
