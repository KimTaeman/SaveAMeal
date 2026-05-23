import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/features/donor/presentation/widgets/donor_bottom_nav.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class DonorDashboardScreen extends ConsumerWidget {
  const DonorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.asData?.value;
    final donorId = user?.uid ?? '';

    if (donorId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final batchesAsync = ref.watch(activeBatchesProvider(donorId));
    final metricsAsync = ref.watch(donorMetricsProvider(donorId));

    if (batchesAsync.isLoading &&
        !batchesAsync.hasValue &&
        metricsAsync.isLoading &&
        !metricsAsync.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final batches = batchesAsync.asData?.value ?? [];
    final metrics = metricsAsync.asData?.value ?? DonorMetrics.empty;
    final isOffline = batchesAsync.hasError || metricsAsync.hasError;

    final orgName = user?.name ?? 'Donor';
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isOffline) _OfflineBanner(context: context),
            const _DashboardHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WelcomeSection(orgName: orgName),
                    _TotalDonatedCard(metrics: metrics),
                    const _LogBatchButton(),
                    _RecentDonationsSection(batches: batches),
                    SizedBox(height: Spacing.md),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DonorBottomNav(
        currentIndex: 0,
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
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      color: ac.warning,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: Text(
        'You are offline. Showing last known data.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: ac.onWarning),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: cs.primary),
              const SizedBox(width: Spacing.xs),
              Text('SaveAMeal', style: textTheme.titleLarge),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: null,
          ),
        ],
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection({required this.orgName});

  final String orgName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $orgName',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Here is your impact summary for this month.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TotalDonatedCard extends StatelessWidget {
  const _TotalDonatedCard({required this.metrics});

  final DonorMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ac = Theme.of(context).extension<AppColors>()!;

    return Card(
      margin: const EdgeInsets.all(Spacing.md),
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(height: 4, color: cs.primary),
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL DONATED',
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${metrics.totalKg}',
                              style: textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ac.warning,
                              ),
                            ),
                            TextSpan(
                              text: ' kg',
                              style: textTheme.titleMedium?.copyWith(
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    radius: 24,
                    child: Icon(Icons.recycling, size: 32, color: cs.primary),
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

class _LogBatchButton extends StatelessWidget {
  const _LogBatchButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: FilledButton.icon(
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Log Surplus Batch'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: const StadiumBorder(),
        ),
        onPressed: () => context.push('/donor/log'),
      ),
    );
  }
}

class _RecentDonationsSection extends StatelessWidget {
  const _RecentDonationsSection({required this.batches});

  final List<Batch> batches;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Donations', style: textTheme.titleMedium),
              TextButton(
                onPressed: () => context.push('/donor/batches'),
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        if (batches.isEmpty)
          const _EmptyBatchesCard()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: batches.length,
            itemBuilder: (_, i) => _BatchCard(batch: batches[i]),
          ),
      ],
    );
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.batch});

  final Batch batch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final shortId = batch.id.length >= 8
        ? batch.id.substring(0, 8).toUpperCase()
        : batch.id.toUpperCase();

    final subtitle =
        '${batch.portions} items • ${batch.weightKg}kg • ${_statusLabel(batch.status)} • ${_formatDate(batch.createdAt)}';

    final trailing = batch.status == BatchStatus.open
        ? IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => context.push('/donor/batch/${batch.id}/qr'),
          )
        : Icon(Icons.check_circle_outline, color: ac.success);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: Card(
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        child: ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2_outlined, color: cs.onSurfaceVariant),
          ),
          title: Text(
            'Batch #$shortId',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle, style: textTheme.bodySmall),
          trailing: trailing,
        ),
      ),
    );
  }

  String _statusLabel(BatchStatus status) => switch (status) {
    BatchStatus.open => 'Pending',
    BatchStatus.claimed => 'Claimed',
    BatchStatus.pickedUp => 'Collected',
    BatchStatus.delivered => 'Delivered',
    BatchStatus.closed => 'Closed',
  };

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;
    if (isToday) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $h:$m $ampm';
    }
    if (isYesterday) return 'Yesterday';
    const months = [
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
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

class _EmptyBatchesCard extends StatelessWidget {
  const _EmptyBatchesCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism, size: 64, color: cs.primary),
          const SizedBox(height: Spacing.md),
          Text('No donations yet', style: textTheme.titleMedium),
          const SizedBox(height: Spacing.md),
          FilledButton(
            onPressed: () => context.push('/donor/log'),
            child: const Text('Log your first batch'),
          ),
        ],
      ),
    );
  }
}
