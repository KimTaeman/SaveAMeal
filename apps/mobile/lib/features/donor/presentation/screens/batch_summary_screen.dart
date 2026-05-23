import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/batch_item.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';
import 'package:saveameal/features/donor/presentation/providers/batch_session_provider.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/services/service_providers.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:uuid/uuid.dart';

class BatchSummaryScreen extends ConsumerStatefulWidget {
  const BatchSummaryScreen({super.key});

  @override
  ConsumerState<BatchSummaryScreen> createState() => _BatchSummaryScreenState();
}

class _BatchSummaryScreenState extends ConsumerState<BatchSummaryScreen> {
  final String _batchId = const Uuid().v4();
  bool _submitting = false;

  String get _shortBatchLabel =>
      'Batch #${_batchId.replaceAll('-', '').substring(0, 4).toUpperCase()}';

  Future<void> _submit(List<BatchItem> items, String donorId) async {
    if (items.isEmpty || _submitting) return;
    setState(() => _submitting = true);

    final batch = Batch(
      id: _batchId,
      donorId: donorId,
      items: items,
      pickupAddress: '',
      status: BatchStatus.open,
      qrCode: 'saveameal://batch/$_batchId',
    );

    try {
      await ref.read(createBatchUsecaseProvider).call(batch);
      _uploadPhotosFireAndForget(items);
      ref.read(batchSessionProvider.notifier).clear();
      if (mounted) context.go('/donor');
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit batch: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _uploadPhotosFireAndForget(List<BatchItem> items) {
    final storage = ref.read(storageServiceProvider);
    for (var i = 0; i < items.length; i++) {
      final path = items[i].localPhotoPath;
      if (path == null) continue;
      unawaited(() async {
        try {
          await storage.uploadBatchPhoto(_batchId, '$i', File(path));
        } catch (_) {
          // fire-and-forget — ignore upload failures
        }
      }());
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(batchSessionProvider);
    final donorId = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final totalWeight = items.fold<double>(0, (s, i) => s + i.weightKg);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Summary'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No items added yet.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.sm,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ItemCard(
                      item: items[i],
                      onDelete: () =>
                          ref.read(batchSessionProvider.notifier).remove(i),
                    ),
                  ),
          ),
          _StatsBar(itemCount: items.length, totalKg: totalWeight),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.sm,
              Spacing.md,
              Spacing.xs,
            ),
            child: OutlinedButton(
              onPressed: () {
                context.pop();
                context.pop();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: const StadiumBorder(),
              ),
              child: const Text('Add Another Item'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.xs,
              Spacing.md,
              Spacing.md,
            ),
            child: FilledButton(
              onPressed: (items.isEmpty || _submitting)
                  ? null
                  : () => _submit(items, donorId),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: const StadiumBorder(),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Submit $_shortBatchLabel'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onDelete});
  final BatchItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: cs.primary),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _categoryIcon(item.category),
                    color: cs.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${item.weightKg}kg',
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _ExpiryChip(expiryTime: item.expiryTime),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.onSurfaceVariant),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(FoodCategory c) => switch (c) {
    FoodCategory.bakery => Icons.bakery_dining,
    FoodCategory.produce => Icons.eco,
    FoodCategory.dairy => Icons.egg_outlined,
    FoodCategory.meat => Icons.set_meal,
    FoodCategory.beverages => Icons.local_cafe_outlined,
    FoodCategory.other => Icons.category_outlined,
  };
}

class _ExpiryChip extends StatelessWidget {
  const _ExpiryChip({required this.expiryTime});
  final DateTime expiryTime;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label(),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: cs.onPrimaryContainer),
      ),
    );
  }

  String _label() {
    final diff = expiryTime.difference(DateTime.now());
    if (diff.inHours < 1) return 'Expires soon';
    if (diff.inHours < 24) return 'Expires in ${diff.inHours}h';
    if (diff.inDays == 1) return 'Expires tomorrow';
    return 'Expires in ${diff.inDays}d';
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.itemCount, required this.totalKg});
  final int itemCount;
  final double totalKg;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Text(
        '$itemCount items  •  ${totalKg.toStringAsFixed(1)} kg total',
        style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
