import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_account_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/beneficiary_bottom_nav.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _formatMonthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

class BeneficiaryAccountScreen extends ConsumerStatefulWidget {
  const BeneficiaryAccountScreen({super.key});

  @override
  ConsumerState<BeneficiaryAccountScreen> createState() =>
      _BeneficiaryAccountScreenState();
}

class _BeneficiaryAccountScreenState
    extends ConsumerState<BeneficiaryAccountScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final profileAsync = ref.watch(currentBeneficiaryProfileProvider);

    if (uid.isEmpty || (profileAsync.isLoading && !profileAsync.hasValue)) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final profile = profileAsync.asData?.value;
    if (profile == null && !profileAsync.hasError) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final orgName = profile?.orgName ?? profile?.name ?? '';
    final joinedText = profile?.joinedAt != null
        ? _formatMonthYear(profile!.joinedAt!)
        : '';
    final hasError = profileAsync.hasError;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: cs.surface,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.location_on, color: cs.primary, size: 20),
            SizedBox(width: Spacing.xs),
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
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasError) const _OfflineBanner(),
            SizedBox(height: Spacing.lg),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.primary, width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: cs.primaryContainer,
                  child: profile?.photoUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: profile!.photoUrl!,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorWidget: (ctx, url, err) =>
                                Icon(Icons.domain, size: 40, color: cs.primary),
                          ),
                        )
                      : Icon(Icons.domain, size: 40, color: cs.primary),
                ),
              ),
            ),
            SizedBox(height: Spacing.sm),
            Center(
              child: Text(
                orgName,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ),
            SizedBox(height: Spacing.xs),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: ac.warning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'BENEFICIARY',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ac.onWarning,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: Spacing.xs),
            Center(
              child: Text(
                joinedText.isEmpty ? '' : 'Joined $joinedText',
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(height: Spacing.sm),
            Center(child: Container(height: 2, width: 120, color: cs.primary)),
            SizedBox(height: Spacing.md),
            Card(
              color: cs.surfaceContainerLow,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(Spacing.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant, color: cs.primary, size: 18),
                        SizedBox(width: Spacing.xs),
                        Text(
                          'MEALS RECEIVED',
                          style: textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Spacing.xs),
                    Text(
                      '${profile?.mealsReceived ?? 0}',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: Spacing.xs),
                    Text(
                      'Providing nourishment since day one',
                      style: textTheme.bodySmall?.copyWith(color: cs.primary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: Spacing.lg),
            Text(
              'ACCOUNT SETTINGS',
              style: textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: Spacing.xs),
            Card(
              color: cs.surfaceContainerLow,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: _settingsIcon(
                      cs,
                      Icons.notifications_active_outlined,
                    ),
                    title: Text(
                      'Push Notifications',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'New Deliveries',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (v) =>
                          setState(() => _notificationsEnabled = v),
                      activeThumbColor: cs.primary,
                    ),
                  ),
                  Divider(height: 1, color: cs.outlineVariant),
                  ListTile(
                    leading: _settingsIcon(cs, Icons.person_outline),
                    title: Text(
                      'Personal Information',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: cs.onSurfaceVariant,
                    ),
                    onTap: () => context.push('/beneficiary/account/personal'),
                  ),
                  Divider(height: 1, color: cs.outlineVariant),
                  ListTile(
                    leading: _settingsIcon(cs, Icons.business_outlined),
                    title: Text(
                      'Organization Profile',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: cs.onSurfaceVariant,
                    ),
                    onTap: () => context.push('/beneficiary/account/org'),
                  ),
                ],
              ),
            ),
            SizedBox(height: Spacing.lg),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: ac.danger,
                side: BorderSide(color: ac.danger, width: 1.5),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              onPressed: () async {
                await ref.read(signOutUsecaseProvider).call();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.logout, size: 18),
                  SizedBox(width: Spacing.sm),
                  Text(
                    'Log Out',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Spacing.md),
          ],
        ),
      ),
      bottomNavigationBar: BeneficiaryBottomNav(
        currentIndex: 3,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/beneficiary');
            case 3:
              context.go('/beneficiary/account');
          }
        },
      ),
    );
  }

  Widget _settingsIcon(ColorScheme cs, IconData icon) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: cs.primaryContainer,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: cs.primary, size: 22),
  );
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      color: ac.warning,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: Text(
        'Could not load data. Check your connection.',
        style: textTheme.bodySmall?.copyWith(color: ac.onWarning),
        textAlign: TextAlign.center,
      ),
    );
  }
}
