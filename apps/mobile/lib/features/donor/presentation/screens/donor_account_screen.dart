import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_account_provider.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/features/donor/presentation/widgets/donor_bottom_nav.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class DonorAccountScreen extends ConsumerStatefulWidget {
  const DonorAccountScreen({super.key});

  @override
  ConsumerState<DonorAccountScreen> createState() => _DonorAccountScreenState();
}

class _DonorAccountScreenState extends ConsumerState<DonorAccountScreen> {
  bool _notificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.asData?.value;
    final uid = user?.uid ?? '';

    final userModelAsync = ref.watch(currentUserProvider);
    final metricsAsync = uid.isNotEmpty
        ? ref.watch(donorMetricsProvider(uid))
        : const AsyncValue<DonorMetrics>.data(DonorMetrics.empty);

    final userModel = userModelAsync.asData?.value;
    final orgName =
        userModel?.orgName ?? userModel?.name ?? user?.name ?? 'Donor';
    final photoUrl = userModel?.photoUrl;
    final metrics = metricsAsync.asData?.value ?? DonorMetrics.empty;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Color(0xFF006E2F), size: 20),
            const SizedBox(width: 4),
            Text(
              'SaveAMeal',
              style: textTheme.titleLarge?.copyWith(
                color: const Color(0xFF006E2F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: null,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(Spacing.md),
        itemCount: 1,
        itemBuilder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile card
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Color(0xFF006E2F), width: 2.5),
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: cs.surfaceContainerHigh,
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorWidget: (ctx, url, err) =>
                                      const Icon(Icons.store, size: 40),
                                ),
                              )
                            : Icon(
                                Icons.store,
                                size: 40,
                                color: cs.onSurfaceVariant,
                              ),
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: Spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7A400),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '★ Donor',
                        style: textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF523D00),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      orgName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    // Stat chips
                    Row(
                      children: [
                        Expanded(
                          child: _StatChip(
                            icon: Icons.eco,
                            value: '${metrics.totalKg} kg',
                            label: 'Total Donations',
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: _StatChip(
                            icon: Icons.favorite,
                            value: '${metrics.totalDeliveries}',
                            label: 'Organizations Helped',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            // Account Settings section
            Text(
              'ACCOUNT SETTINGS',
              style: textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Push Notifications'),
                    subtitle: const Text('New Pickups'),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (v) =>
                          setState(() => _notificationsEnabled = v),
                    ),
                  ),
                  const Divider(height: 1, indent: Spacing.md),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Personal Information'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/donor/account/personal'),
                  ),
                  const Divider(height: 1, indent: Spacing.md),
                  ListTile(
                    leading: const Icon(Icons.store_outlined),
                    title: const Text('Organization Profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/donor/account/org'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),
            // Log out button
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: ac.danger,
                side: BorderSide(color: ac.danger),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () async {
                final usecase = ref.read(signOutUsecaseProvider);
                await usecase.call();
              },
              child: const Text('Log Out'),
            ),
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
      bottomNavigationBar: DonorBottomNav(
        currentIndex: 3,
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF006E2F), size: 20),
          const SizedBox(height: Spacing.xs),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF006E2F),
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: const Color(0xFF006E2F),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
