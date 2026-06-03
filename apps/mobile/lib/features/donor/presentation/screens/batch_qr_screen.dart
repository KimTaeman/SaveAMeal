import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class BatchQrScreen extends ConsumerWidget {
  const BatchQrScreen({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final batchAsync = ref.watch(batchByIdProvider(batchId));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/donor')),
        titleSpacing: 0,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 28),
            const SizedBox(width: Spacing.xs),
            Text(
              'SaveAMeal',
              style: textTheme.titleLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pickup Code',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'Show this to the store staff',
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xl),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(Spacing.lg),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: QrImageView(
                    data: batchId,
                    version: QrVersions.auto,
                    size: 220,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                batchId,
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.lg),
              batchAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
                data: (batch) => _BatchSummaryCard(
                  batch: batch,
                  cs: cs,
                  ac: ac,
                  textTheme: textTheme,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              OutlinedButton.icon(
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to Dashboard'),
                onPressed: () => context.go('/donor'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: const StadiumBorder(),
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchSummaryCard extends StatelessWidget {
  const _BatchSummaryCard({
    required this.batch,
    required this.cs,
    required this.ac,
    required this.textTheme,
  });

  final Batch batch;
  final ColorScheme cs;
  final AppColors ac;
  final TextTheme textTheme;

  String _formatExpiry(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return 'Valid today until $h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    if (batch.items.isEmpty) return const SizedBox.shrink();

    final soonestExpiry = batch.items
        .map((i) => i.expiryTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'BATCH SUMMARY',
            style: textTheme.labelSmall?.copyWith(
              color: ac.brand,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            '${batch.portions} ${batch.portions == 1 ? 'item' : 'items'}  •  '
            '${batch.weightKg.toStringAsFixed(1)} kg',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (batch.items.isNotEmpty) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              batch.description,
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: Spacing.xs),
          Text(
            _formatExpiry(soonestExpiry),
            style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
