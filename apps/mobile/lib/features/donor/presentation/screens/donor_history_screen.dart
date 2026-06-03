import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/features/donor/presentation/widgets/donor_bottom_nav.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

enum _HistoryFilter { all, completed, inProgress }

String _formatBatchDate(DateTime dt) {
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
  return '${months[dt.month]} ${dt.day}, ${dt.year} · $h:$m $ampm';
}

class DonorHistoryScreen extends ConsumerStatefulWidget {
  const DonorHistoryScreen({super.key});

  @override
  ConsumerState<DonorHistoryScreen> createState() => _DonorHistoryScreenState();
}

class _DonorHistoryScreenState extends ConsumerState<DonorHistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;
  String _searchQuery = '';
  int _currentPage = 0;
  static const _pageSize = 5;

  List<Batch> _applyFilterAndSearch(List<Batch> batches) {
    var filtered = switch (_filter) {
      _HistoryFilter.all => batches,
      _HistoryFilter.completed =>
        batches
            .where(
              (b) =>
                  b.status == BatchStatus.delivered ||
                  b.status == BatchStatus.closed,
            )
            .toList(),
      _HistoryFilter.inProgress =>
        batches
            .where(
              (b) =>
                  b.status == BatchStatus.open ||
                  b.status == BatchStatus.claimed ||
                  b.status == BatchStatus.pickedUp,
            )
            .toList(),
    };

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((b) {
        final shortId = b.id
            .substring(0, b.id.length.clamp(0, 4))
            .toLowerCase();
        final dateStr = b.createdAt != null
            ? _formatDate(b.createdAt!).toLowerCase()
            : '';
        return shortId.contains(q) || dateStr.contains(q);
      }).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final donorId = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final batchesAsync = donorId.isEmpty
        ? const AsyncValue<List<Batch>>.loading()
        : ref.watch(allBatchesProvider(donorId));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Donation History',
          style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/donor/log'),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SearchBar(
              onChanged: (q) => setState(() {
                _searchQuery = q;
                _currentPage = 0;
              }),
            ),
            _FilterChipsRow(
              selected: _filter,
              onChanged: (f) => setState(() {
                _filter = f;
                _currentPage = 0;
              }),
            ),
            Expanded(
              child: batchesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(
                  onRetry: () => ref.invalidate(allBatchesProvider(donorId)),
                ),
                data: (allBatches) {
                  final filtered = _applyFilterAndSearch(allBatches);
                  if (filtered.isEmpty) return const _EmptyState();

                  final totalPages = ((filtered.length - 1) ~/ _pageSize) + 1;
                  final page = _currentPage.clamp(0, totalPages - 1);
                  final start = page * _pageSize;
                  final end = (start + _pageSize).clamp(0, filtered.length);
                  final pageBatches = filtered.sublist(start, end);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Batches',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${filtered.length} Total',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.md,
                          ),
                          itemCount: pageBatches.length,
                          itemBuilder: (context, i) =>
                              _BatchHistoryCard(batch: pageBatches[i]),
                        ),
                      ),
                      if (totalPages > 1)
                        _PaginationRow(
                          currentPage: page,
                          totalPages: totalPages,
                          onPageChanged: (p) =>
                              setState(() => _currentPage = p),
                        ),
                      const SizedBox(height: Spacing.md),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DonorBottomNav(
        currentIndex: 2,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/donor');
            case 1:
              context.go('/donor/impact');
            case 2:
              context.go('/donor/batches');
            case 3:
              context.go('/donor/account');
          }
        },
      ),
    );
  }

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
    return '${months[dt.month]} ${dt.day}';
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search batch ID or date...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: cs.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
        ),
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({required this.selected, required this.onChanged});

  final _HistoryFilter selected;
  final ValueChanged<_HistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: selected == _HistoryFilter.all,
            onTap: () => onChanged(_HistoryFilter.all),
            cs: cs,
          ),
          const SizedBox(width: Spacing.sm),
          _FilterChip(
            label: 'Completed',
            isSelected: selected == _HistoryFilter.completed,
            onTap: () => onChanged(_HistoryFilter.completed),
            cs: cs,
          ),
          const SizedBox(width: Spacing.sm),
          _FilterChip(
            label: 'In Progress',
            isSelected: selected == _HistoryFilter.inProgress,
            onTap: () => onChanged(_HistoryFilter.inProgress),
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.cs,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: isSelected,
    onSelected: (_) => onTap(),
    selectedColor: cs.primary,
    labelStyle: TextStyle(
      color: isSelected ? cs.onPrimary : cs.onSurface,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
    ),
    checkmarkColor: cs.onPrimary,
  );
}

class _BatchHistoryCard extends StatelessWidget {
  const _BatchHistoryCard({required this.batch});

  final Batch batch;

  Color _accentColor(BatchStatus s, AppColors ac, ColorScheme cs) =>
      switch (s) {
        BatchStatus.delivered || BatchStatus.closed => cs.primary,
        BatchStatus.open ||
        BatchStatus.claimed ||
        BatchStatus.pickedUp => ac.warning,
        _ => ac.danger,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final accent = _accentColor(batch.status, ac, cs);
    final shortId = batch.id
        .substring(0, batch.id.length.clamp(0, 4))
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/donor/batch/${batch.id}'),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                const SizedBox(width: Spacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: accent,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#$shortId',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (batch.createdAt != null)
                          Text(
                            _formatDateTime(batch.createdAt!),
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: Spacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.scale_outlined,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${batch.weightKg.toStringAsFixed(1)} kg',
                              style: textTheme.bodySmall,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${batch.portions} items',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.sm,
                  ),
                  child: _StatusBadge(status: batch.status),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) => _formatBatchDate(dt);
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BatchStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final isDone =
        status == BatchStatus.delivered || status == BatchStatus.closed;
    final color = isDone ? cs.primary : ac.warning;
    final icon = isDone ? Icons.check_circle : Icons.sync;
    final label = isDone ? 'DONE' : 'ACTIVE';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PaginationRow extends StatelessWidget {
  const _PaginationRow({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pages = List.generate(totalPages, (i) => i);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 0
                ? () => onPageChanged(currentPage - 1)
                : null,
          ),
          ...pages.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: p == currentPage
                  ? FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                        backgroundColor: cs.primary,
                      ),
                      child: Text('${p + 1}'),
                    )
                  : OutlinedButton(
                      onPressed: () => onPageChanged(p),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text('${p + 1}'),
                    ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.volunteer_activism, size: 64, color: cs.primary),
          const SizedBox(height: Spacing.md),
          Text(
            'No donations yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: Spacing.sm),
          const Text('Could not load donations'),
          const SizedBox(height: Spacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
