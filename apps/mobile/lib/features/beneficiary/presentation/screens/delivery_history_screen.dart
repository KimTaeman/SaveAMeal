import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/delivery_history_notifier.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/delivery_history_row.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/order_history_stats_bar.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

/// Full paginated delivery history screen for beneficiaries.
/// Route: /beneficiary/history
/// Entry point: "View All" TextButton in RecentDeliveriesSection on DeliveryDetailScreen.
class DeliveryHistoryScreen extends ConsumerStatefulWidget {
  const DeliveryHistoryScreen({super.key, required this.beneficiaryId});

  final String beneficiaryId;

  @override
  ConsumerState<DeliveryHistoryScreen> createState() =>
      _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends ConsumerState<DeliveryHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(deliveryHistoryProvider(widget.beneficiaryId));
    final notifier = ref.read(
      deliveryHistoryProvider(widget.beneficiaryId).notifier,
    );

    return asyncState.when(
      loading: () => Scaffold(
        appBar: _buildAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => Scaffold(
        appBar: _buildAppBar(context),
        body: _ErrorBody(onRetry: notifier.refresh),
      ),
      data: (state) {
        if (state.items.isEmpty && !state.hasMore) {
          return Scaffold(
            appBar: _buildAppBar(context),
            body: const _EmptyBody(),
          );
        }
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: notifier.refresh,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context),
                _SubtitleSliver(beneficiaryId: widget.beneficiaryId),
                SliverToBoxAdapter(child: OrderHistoryStatsBar(state: state)),
                SliverList.builder(
                  itemCount: state.items.length + 1,
                  itemBuilder: (context, index) {
                    // Last item is the load-more footer
                    if (index == state.items.length) {
                      return _LoadMoreFooter(
                        state: state,
                        onLoadMore: notifier.loadNextPage,
                      );
                    }
                    return DeliveryHistoryRow(delivery: state.items[index]);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      leading: const BackButton(),
      title: Text('Order History', style: textTheme.titleLarge),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SliverAppBar(
      leading: const BackButton(),
      title: Text('Order History', style: textTheme.titleLarge),
      floating: true,
      snap: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  }
}

class _SubtitleSliver extends ConsumerWidget {
  const _SubtitleSliver({required this.beneficiaryId});

  final String beneficiaryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final currentUser = ref.watch(authStateProvider).asData?.value;
    final orgName = currentUser?.name ?? 'your organisation';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Text(
          'Review past deliveries to $orgName.',
          style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.state, required this.onLoadMore});

  final DeliveryHistoryState state;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Inline load-more error row
        if (state.loadMoreError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: ac.danger, size: 16),
                const SizedBox(width: Spacing.xs),
                Text(
                  'Failed to load more. ',
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: onLoadMore,
                  child: Text(
                    'Retry',
                    style: textTheme.labelSmall?.copyWith(color: cs.primary),
                  ),
                ),
              ],
            ),
          ),

        // Load More button or "All deliveries loaded" text
        if (state.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: OutlinedButton.icon(
              onPressed: state.isLoadingMore ? null : onLoadMore,
              icon: state.isLoadingMore
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  : Icon(Icons.expand_more, color: cs.primary),
              label: Text(
                'Load More History',
                style: textTheme.labelLarge?.copyWith(color: cs.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.primary),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Center(
              child: Text(
                'All deliveries loaded',
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.inbox_outlined,
                size: 72,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Your delivery history will appear here',
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.cloud_off,
                size: 56,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Could not load delivery history.',
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
