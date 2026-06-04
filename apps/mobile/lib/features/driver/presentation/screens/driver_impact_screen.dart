import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/domain/entities/driver_impact.dart';
import 'package:saveameal/features/driver/domain/entities/leaderboard_entry.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_impact_provider.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class DriverImpactScreen extends ConsumerWidget {
  const DriverImpactScreen({super.key});

  static const _period = 'thisMonth';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final impactAsync = ref.watch(driverImpactProvider(uid));
    final leaderboardAsync = ref.watch(leaderboardProvider(uid, _period));

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: cs.surface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: cs.primary, size: 20),
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
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      bottomNavigationBar: _DriverBottomNav(currentIndex: 1),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          impactAsync.when(
            loading: () => const _RankCardSkeleton(),
            error: (err, _) => const _RankCardError(),
            data: (impact) => _RankCard(impact: impact),
          ),
          const SizedBox(height: Spacing.md),
          impactAsync.when(
            loading: () => const _StatsRowSkeleton(),
            error: (err, _) => const SizedBox.shrink(),
            data: (impact) => _StatsRow(impact: impact),
          ),
          const SizedBox(height: Spacing.lg),
          leaderboardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => const _LeaderboardError(),
            data: (entries) => _LeaderboardSection(entries: entries),
          ),
          const SizedBox(height: Spacing.md),
        ],
      ),
    );
  }
}

// ── Rank card ──────────────────────────────────────────────────────────────

class _RankCard extends StatelessWidget {
  const _RankCard({required this.impact});
  final DriverImpact impact;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ac.brand, ac.brandLight],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'CURRENT RANK',
            style: textTheme.labelSmall?.copyWith(
              color: Colors.white70,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          if (impact.rank == 0 || impact.totalDrivers == 0) ...[
            Text(
              'Not yet ranked',
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Complete your first delivery to earn a rank',
              style: textTheme.labelSmall?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '#${impact.rank}',
                  style: textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                Text(
                  'of ${impact.totalDrivers} Drivers',
                  style: textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: impact.rankProgress.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              '${impact.rankProgressCurrent} / ${impact.rankProgressTarget} Meals to ${impact.nextRankName} Rank',
              style: textTheme.labelSmall?.copyWith(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _RankCardSkeleton extends StatelessWidget {
  const _RankCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _RankCardError extends StatelessWidget {
  const _RankCardError();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('Could not load impact data'),
    );
  }
}

// ── Stats row ──────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.impact});
  final DriverImpact impact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.restaurant,
            label: 'Meals Saved',
            value: impact.mealsSaved.toString(),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.eco,
            label: 'Sprout Points',
            value: _formatPoints(impact.sproutPoints),
          ),
        ),
      ],
    );
  }

  static String _formatPoints(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : n.toString();
}

class _StatsRowSkeleton extends StatelessWidget {
  const _StatsRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: ac.brand, size: 28),
          const SizedBox(height: Spacing.xs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ac.brand,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Leaderboard section ────────────────────────────────────────────────────

class _LeaderboardSection extends StatelessWidget {
  const _LeaderboardSection({required this.entries});
  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Top Drivers',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: ac.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'This Month',
                style: textTheme.labelMedium?.copyWith(color: ac.brand),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < entries.length; i++) ...[
                _LeaderboardRow(entry: entries[i]),
                if (i < entries.length - 1)
                  const Divider(height: 1, indent: Spacing.md),
              ],
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        Center(
          child: TextButton(
            key: const Key('view_full_leaderboard'),
            onPressed: () {},
            child: Text(
              'View Full Leaderboard',
              style: TextStyle(color: ac.brand),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;

    return Container(
      decoration: entry.isCurrentUser
          ? BoxDecoration(
              color: ac.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            )
          : null,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${entry.rank}',
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          _Avatar(avatarUrl: entry.avatarUrl, name: entry.driverName),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isCurrentUser
                      ? '${entry.driverName} (You)'
                      : entry.driverName,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: entry.isCurrentUser ? ac.brand : null,
                  ),
                ),
                Text(
                  entry.zone,
                  style: textTheme.bodySmall?.copyWith(
                    color: entry.isCurrentUser ? ac.brand : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.score}',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: entry.isCurrentUser ? ac.brand : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.avatarUrl, required this.name});
  final String? avatarUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: ac.brandLight.withValues(alpha: 0.3),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(color: ac.brand, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _LeaderboardError extends StatelessWidget {
  const _LeaderboardError();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Could not load leaderboard'));
  }
}

// ── Bottom nav ─────────────────────────────────────────────────────────────

class _DriverBottomNav extends StatelessWidget {
  const _DriverBottomNav({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        if (i == 0) context.go('/driver');
        if (i == 1) context.go('/driver/impact');
        if (i == 2) context.go('/driver/account');
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.eco_outlined),
          selectedIcon: Icon(Icons.eco),
          label: 'Impact',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    );
  }
}
