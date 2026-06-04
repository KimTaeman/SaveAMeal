import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/domain/entities/leaderboard_entry.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_impact_provider.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class DriverLeaderboardScreen extends ConsumerWidget {
  const DriverLeaderboardScreen({super.key});

  static const _period = 'thisMonth';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final leaderboardAsync = ref.watch(leaderboardProvider(uid, _period));

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ac = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: const Text('Leaderboard'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: Spacing.md),
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
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: Spacing.sm),
              const Text('Could not load leaderboard'),
              const SizedBox(height: Spacing.sm),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(leaderboardProvider(uid, _period)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (entries) => entries.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      'No drivers ranked yet',
                      style: textTheme.titleMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'Complete a delivery to appear here',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(Spacing.md),
                itemCount: entries.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, i) => _LeaderboardRow(entry: entries[i]),
              ),
      ),
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

    final isTop3 = entry.rank <= 3;

    return Container(
      decoration: entry.isCurrentUser
          ? BoxDecoration(
              color: ac.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: isTop3
                ? _MedalIcon(rank: entry.rank)
                : Text(
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
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: entry.isCurrentUser ? ac.brand : cs.onSurface,
            ),
          ),
          const SizedBox(width: Spacing.xs),
          Text(
            'meals',
            style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MedalIcon extends StatelessWidget {
  const _MedalIcon({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final color = switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      _ => const Color(0xFFCD7F32),
    };
    return Icon(Icons.emoji_events, color: color, size: 24);
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
        radius: 20,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: ac.brandLight.withValues(alpha: 0.3),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(color: ac.brand, fontWeight: FontWeight.bold),
      ),
    );
  }
}
