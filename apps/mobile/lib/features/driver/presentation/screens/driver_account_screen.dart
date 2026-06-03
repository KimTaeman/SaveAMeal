import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_profile_provider.dart';
import 'package:saveameal/features/driver/presentation/widgets/driver_avatar_widget.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class DriverAccountScreen extends ConsumerStatefulWidget {
  const DriverAccountScreen({super.key});

  @override
  ConsumerState<DriverAccountScreen> createState() =>
      _DriverAccountScreenState();
}

class _DriverAccountScreenState extends ConsumerState<DriverAccountScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final profileAsync = ref.watch(driverProfileProvider);

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
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: Spacing.sm),
              Text('Failed to load profile', style: textTheme.bodyMedium),
              const SizedBox(height: Spacing.sm),
              FilledButton(
                onPressed: () => ref.invalidate(driverProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_outlined,
                    size: 48,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Profile unavailable offline',
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  FilledButton(
                    onPressed: () => ref.invalidate(driverProfileProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return _AccountBody(
            profile: profile,
            notificationsEnabled: _notificationsEnabled,
            onNotificationsChanged: (val) =>
                setState(() => _notificationsEnabled = val),
            onLogOut: () async {
              await ref.read(signOutUsecaseProvider).call();
            },
            ac: ac,
          );
        },
      ),
      bottomNavigationBar: const _DriverBottomNav(currentIndex: 2),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _AccountBody extends StatelessWidget {
  const _AccountBody({
    required this.profile,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
    required this.onLogOut,
    required this.ac,
  });

  final DriverProfile profile;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onLogOut;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.md,
      ),
      itemCount: 1,
      itemBuilder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Profile header ──────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                DriverAvatarWidget(photoUrl: profile.photoUrl),
                const SizedBox(height: Spacing.sm),
                Text(
                  profile.name,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                _VolunteerBadge(cs: cs, textTheme: textTheme),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          // ── Stats row ───────────────────────────────────────────────────
          _StatsRow(profile: profile),
          const SizedBox(height: Spacing.lg),
          // ── Settings list ───────────────────────────────────────────────
          Card(
            color: cs.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Push Notifications
                SwitchListTile(
                  secondary: Icon(
                    Icons.notifications_none,
                    color: cs.onSurface,
                  ),
                  title: Text('Push Notifications', style: textTheme.bodyLarge),
                  subtitle: Text(
                    'New Deliveries',
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  value: notificationsEnabled,
                  onChanged: onNotificationsChanged,
                ),
                Divider(
                  height: 1,
                  indent: Spacing.md,
                  color: cs.outlineVariant,
                ),
                // Personal Information
                ListTile(
                  leading: Icon(Icons.person_outline, color: cs.onSurface),
                  title: Text(
                    'Personal Information',
                    style: textTheme.bodyLarge,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: cs.onSurfaceVariant,
                  ),
                  onTap: () => context.push('/driver/account/personal-info'),
                ),
                Divider(
                  height: 1,
                  indent: Spacing.md,
                  color: cs.outlineVariant,
                ),
                // Vehicle Details
                ListTile(
                  leading: Icon(
                    Icons.directions_car_outlined,
                    color: cs.onSurface,
                  ),
                  title: Text('Vehicle Details', style: textTheme.bodyLarge),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: cs.onSurfaceVariant,
                  ),
                  onTap: () => context.push('/driver/account/vehicle-details'),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          // ── Log Out ─────────────────────────────────────────────────────
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: ac.danger,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            onPressed: onLogOut,
          ),
          const SizedBox(height: Spacing.md),
        ],
      ),
    );
  }
}

// ── Volunteer badge ───────────────────────────────────────────────────────────

class _VolunteerBadge extends StatelessWidget {
  const _VolunteerBadge({required this.cs, required this.textTheme});

  final ColorScheme cs;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.volunteer_activism,
            size: 14,
            color: cs.onPrimaryContainer,
          ),
          const SizedBox(width: Spacing.xs),
          Text(
            'Volunteer Driver',
            style: textTheme.labelSmall?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'JOIN DATE',
            value: profile.joinDate ?? '—',
            cs: cs,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _StatCard(
            label: 'TOTAL PICKUPS',
            value: profile.totalPickups?.toString() ?? '—',
            cs: cs,
            textTheme: textTheme,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.cs,
    required this.textTheme,
  });

  final String label;
  final String value;
  final ColorScheme cs;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Spacing.md,
          horizontal: Spacing.sm,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

class _DriverBottomNav extends StatelessWidget {
  const _DriverBottomNav({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        if (i == 0) context.go('/driver');
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
