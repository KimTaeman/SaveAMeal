import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_account_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/beneficiary_bottom_nav.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/order_history_card.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

String _formatWithCommas(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

class BeneficiaryOrderHistoryScreen extends ConsumerWidget {
  const BeneficiaryOrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    if (uid.isEmpty) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final profileAsync = ref.watch(currentBeneficiaryProfileProvider);
    final orgName =
        profileAsync.asData?.value?.orgName ??
        profileAsync.asData?.value?.name ??
        '';

    final orderState = ref.watch(orderHistoryProvider(uid));
    final entries = orderState.entries;
    final hasMore = orderState.hasMore;
    final isLoadingMore = orderState.isLoadingMore;
    final totalMeals = entries.fold<int>(
      0,
      (sum, e) => sum + (e.totalWeightKg * 2.5).round(),
    );
    final deliveryCount = entries.length;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: Spacing.sm),
                Text(
                  'Order History',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Review past deliveries${orgName.isNotEmpty ? ' to $orgName' : ''}.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.restaurant,
                                color: cs.primary,
                                size: 16,
                              ),
                              const SizedBox(width: Spacing.xs),
                              Text(
                                'Total Meals',
                                style: textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            _formatWithCommas(totalMeals),
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Container(height: 3, width: 80, color: cs.primary),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                color: cs.primary,
                                size: 16,
                              ),
                              const SizedBox(width: Spacing.xs),
                              Text(
                                'Deliveries',
                                style: textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            '$deliveryCount',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Container(height: 3, width: 80, color: ac.warning),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.lg),
              ]),
            ),
          ),
          if (entries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 48,
                      color: cs.onSurfaceVariant,
                    ),
                    SizedBox(height: Spacing.sm),
                    Text(
                      'No deliveries yet',
                      style: textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index.isOdd) {
                    return const SizedBox(height: Spacing.sm);
                  }
                  return OrderHistoryCard(entry: entries[index ~/ 2]);
                }, childCount: entries.length * 2 - 1),
              ),
            ),
          if (hasMore)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.xs,
                Spacing.md,
                Spacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.primary,
                    side: BorderSide(color: cs.primary),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Spacing.xl - Spacing.xs,
                      ),
                    ),
                  ),
                  onPressed: isLoadingMore
                      ? null
                      : () => ref
                            .read(orderHistoryProvider(uid).notifier)
                            .loadMore(),
                  child: isLoadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Load More History',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: Spacing.xs),
                            const Icon(Icons.keyboard_arrow_down, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: Spacing.md)),
        ],
      ),
      bottomNavigationBar: BeneficiaryBottomNav(
        currentIndex: 3,
        onDestinationSelected: (i) {
          if (i == 0) context.go('/beneficiary');
          if (i == 1) context.go('/beneficiary/history');
          if (i == 2) context.go('/beneficiary/impact');
          if (i == 3) context.go('/beneficiary/account');
        },
      ),
    );
  }
}
