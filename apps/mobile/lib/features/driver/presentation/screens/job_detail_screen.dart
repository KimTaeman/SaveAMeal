import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/core/exceptions/batch_exceptions.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.batch});

  final BatchSummary batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Details'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: Spacing.md),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Available',
              style: textTheme.labelSmall?.copyWith(
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          _InfoCard(
            children: [
              _AddressRow(
                icon: Icons.storefront,
                label: 'PICKUP FROM',
                name: batch.donorName,
                address: batch.pickupAddress,
              ),
              const Divider(height: 1),
              _AddressRow(
                icon: Icons.volunteer_activism,
                label: 'DROP-OFF TO',
                name: batch.beneficiaryName,
                address: batch.beneficiaryAddress,
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          _InfoCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DETAILS', style: textTheme.labelSmall),
                    const SizedBox(height: Spacing.sm),
                    if (batch.pickupWindowStart != null)
                      _DetailRow(
                        icon: Icons.schedule,
                        text:
                            'Today, ${batch.pickupWindowStart} – ${batch.pickupWindowEnd}',
                      ),
                    if (batch.specialInstructions != null)
                      _DetailRow(
                        icon: Icons.info_outline,
                        text: batch.specialInstructions!,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          _InfoCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Batch Summary', style: textTheme.titleSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: Spacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${batch.totalPortions} Portions',
                            style: textTheme.labelSmall?.copyWith(
                              color: cs.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Wrap(
                      spacing: Spacing.xs,
                      runSpacing: Spacing.xs,
                      children: batch.items
                          .map(
                            (item) => Chip(
                              label: Text(
                                item.name,
                                style: textTheme.labelSmall,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: FilledButton(
            onPressed: () => _onAccept(context, ref),
            child: const Text('Accept Job'),
          ),
        ),
      ),
    );
  }

  Future<void> _onAccept(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
    try {
      await ref.read(driverProvider.notifier).claimBatch(batch.id, uid);
      if (context.mounted) context.go('/driver/rescue');
    } on BatchAlreadyClaimedException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch already taken — try another.')),
        );
        context.pop();
      }
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(children: children),
  );
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.icon,
    required this.label,
    required this.name,
    required this.address,
  });
  final IconData icon;
  final String label;
  final String name;
  final String address;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(color: cs.primary),
                ),
                Text(name, style: textTheme.bodyMedium),
                Text(
                  address,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.xs),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
