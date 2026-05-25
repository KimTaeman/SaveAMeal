import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/services/service_providers.dart';
import 'package:saveameal/shared/theme/spacing.dart';

part 'delivery_completed_screen.g.dart';

// Streams the driver's running points total from Firestore.
// The Cloud Function updates users/{uid}.points after delivery.
@riverpod
Stream<int> _driverPoints(Ref ref, String uid) =>
    ref.watch(firestoreServiceProvider).watchUserPoints(uid);

class DeliveryCompletedScreen extends ConsumerWidget {
  const DeliveryCompletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final batchAsync = ref.watch(activeBatchForDriverProvider(uid));
    final pointsAsync = ref.watch(_driverPointsProvider(uid));

    final batch = batchAsync.asData?.value;
    final points = pointsAsync.asData?.value ?? 0;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void onDone() {
      ref.read(driverProvider.notifier).resetToIdle();
      context.go('/driver');
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: cs.primary, size: 48),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'Delivery Completed!',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),
              if (batch != null)
                Text(
                  "You've successfully rescued and delivered "
                  "${batch.totalPortions} portions of food to ${batch.beneficiaryName}.",
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: Spacing.xl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Impact Earned', style: textTheme.titleSmall),
                          Icon(Icons.eco, color: cs.primary),
                        ],
                      ),
                      const SizedBox(height: Spacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _ImpactTile(
                              value: batch != null
                                  ? '${(batch.totalPortions * 0.4).toStringAsFixed(0)} kg'
                                  : '—',
                              label: 'CO2 SAVED',
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: _ImpactTile(
                              value: '${batch?.totalPortions ?? 0}',
                              label: 'MEALS PROVIDED',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: cs.tertiary, size: 18),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      '+$points Points Earned',
                      style: textTheme.labelMedium?.copyWith(
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  child: const Text('Done'),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onDone,
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImpactTile extends StatelessWidget {
  const _ImpactTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
