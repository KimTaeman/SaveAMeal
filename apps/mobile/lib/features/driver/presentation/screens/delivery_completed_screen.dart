import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class DeliveryCompletedScreen extends ConsumerWidget {
  const DeliveryCompletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read batch from driverProvider.activeBatch — it persists until
    // resetToIdle() and is available even after the batch status becomes
    // 'delivered' (activeBatchForDriverProvider queries status in
    // ['claimed','pickedUp'] and returns null post-delivery).
    final batch = ref.watch(driverProvider).activeBatch;
    // Compute impact from the rescued batch items.
    // CO2: ~2.5 kg CO2 per kg of food rescued (standard food-waste estimate).
    // Meals: ~2 portions per kg (approximate).
    // Points: same formula as confirmDelivery: max(10, items × 10).
    final totalWeightKg = batch == null
        ? 0.0
        : batch.items.fold<double>(0, (s, e) => s + e.weightKg);
    final co2Kg = (totalWeightKg * 2.5).toStringAsFixed(1);
    final mealsCount = batch == null
        ? 0
        : (totalWeightKg * 2).round().clamp(1, 9999);
    final earnedPoints = batch == null
        ? 0
        : (batch.items.isEmpty ? 10 : batch.items.length * 10);

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
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primaryContainer.withValues(alpha: 0.6),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary,
                    ),
                    child: Icon(Icons.check, color: cs.onPrimary, size: 32),
                  ),
                ],
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
                  "$mealsCount meals of food to ${batch.beneficiaryName}.",
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
                              icon: Icons.cloud_outlined,
                              value: '$co2Kg kg',
                              label: 'CO2 SAVED',
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: _ImpactTile(
                              icon: Icons.restaurant,
                              value: '$mealsCount',
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
                      '+$earnedPoints Points Earned',
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
  const _ImpactTile({required this.value, required this.label, this.icon});
  final String value;
  final String label;
  final IconData? icon;

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
          if (icon != null) ...[
            Icon(icon, color: cs.onSurfaceVariant, size: 22),
            const SizedBox(height: Spacing.xs),
          ],
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
