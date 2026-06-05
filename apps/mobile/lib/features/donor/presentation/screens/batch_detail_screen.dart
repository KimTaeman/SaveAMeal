import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/batch_item.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:saveameal/shared/utils/batch_id_formatter.dart';
import 'package:saveameal/shared/utils/batch_status_x.dart';

class BatchDetailScreen extends ConsumerWidget {
  const BatchDetailScreen({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchAsync = ref.watch(batchByIdProvider(batchId));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Batch Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          batchAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (batch) => batch.status == BatchStatus.open
                ? IconButton(
                    icon: const Icon(Icons.qr_code),
                    onPressed: () => context.push('/donor/batch/$batchId/qr'),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: batchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: Spacing.sm),
              const Text('Could not load batch'),
            ],
          ),
        ),
        data: (batch) => _BatchDetailBody(batch: batch, batchId: batchId),
      ),
    );
  }
}

class _BatchDetailBody extends StatelessWidget {
  const _BatchDetailBody({required this.batch, required this.batchId});

  final Batch batch;
  final String batchId;

  String _statusHeading(BatchStatus s) => switch (s) {
    BatchStatus.open => 'Waiting for Pickup',
    BatchStatus.claimed => 'Driver Assigned',
    BatchStatus.pickedUp => 'Collected Successfully',
    BatchStatus.delivered => 'Delivered Successfully',
    BatchStatus.closed => 'Completed',
    BatchStatus.cancelled => 'Cancelled',
  };

  String _statusLabel(BatchStatus s) => s.label;

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month]} ${dt.day}, $h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Batch chip
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text('Batch ${formatBatchId(batchId)}'),
              backgroundColor: cs.tertiaryContainer,
              labelStyle: TextStyle(color: cs.onTertiaryContainer),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          // Status heading
          Text(
            _statusHeading(batch.status),
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (batch.createdAt != null) ...[
            const SizedBox(height: Spacing.xs),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(batch.createdAt!),
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Spacing.sm),
          // Status pill
          _StatusPill(label: 'Status: ${_statusLabel(batch.status)}'),
          const SizedBox(height: Spacing.md),
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.scale_outlined,
                  label: 'Total Weight',
                  value: '${batch.weightKg.toStringAsFixed(1)} kg',
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Total Items',
                  value: '${batch.portions} Products',
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          // Inventory breakdown
          Text(
            'Inventory Breakdown',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Spacing.sm),
          if (batch.items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Text(
                  'No item data available',
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...batch.items.map((item) => _InventoryItemCard(item: item)),
          // Driver section
          if (batch.volunteerName != null) ...[
            const SizedBox(height: Spacing.md),
            _DriverCard(volunteerName: batch.volunteerName!),
          ],
          // Address card
          const SizedBox(height: Spacing.md),
          _AddressCard(address: batch.pickupAddress),
          const SizedBox(height: Spacing.md),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: cs.onPrimary, size: 18),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Icon(icon, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({required this.item});

  final BatchItem item;

  static const _icons = {
    FoodCategory.bakery: Icons.bakery_dining,
    FoodCategory.produce: Icons.eco,
    FoodCategory.dairy: Icons.egg_outlined,
    FoodCategory.meat: Icons.set_meal,
    FoodCategory.beverages: Icons.local_cafe_outlined,
    FoodCategory.other: Icons.category_outlined,
  };

  static const _categoryNames = {
    FoodCategory.bakery: 'Bakery',
    FoodCategory.produce: 'Fruits & Veggies',
    FoodCategory.dairy: 'Dairy',
    FoodCategory.meat: 'Meat',
    FoodCategory.beverages: 'Beverages',
    FoodCategory.other: 'Other',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, color: cs.primary),
            Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.primaryContainer,
                    child: Icon(
                      _icons[item.category] ?? Icons.category_outlined,
                      color: cs.onPrimaryContainer,
                      size: 18,
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
                          _categoryNames[item.category] ?? 'Other',
                          style: textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${item.weightKg.toStringAsFixed(1)}kg',
                      style: textTheme.bodySmall,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.volunteerName});

  final String volunteerName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final initials = volunteerName.isNotEmpty
        ? volunteerName[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.tertiaryContainer,
            child: Text(
              initials,
              style: TextStyle(color: cs.onTertiaryContainer),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collected by',
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                '$volunteerName (Driver)',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              address,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }
}
