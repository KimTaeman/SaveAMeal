import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/active_delivery_card.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/how_pausing_works_section.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/intake_status_toggle.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/visibility_inactive_card.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:saveameal/shared/widgets/logout_button.dart';

class BeneficiaryHomeScreen extends ConsumerWidget {
  const BeneficiaryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    final uid = user?.uid ?? '';

    final availabilityAsync = ref.watch(intakeAvailabilityProvider(uid));
    final deliveriesAsync = ref.watch(activeDeliveriesProvider(uid));

    if (uid.isEmpty ||
        (availabilityAsync.isLoading && !availabilityAsync.hasValue)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final availability =
        availabilityAsync.asData?.value ??
        BeneficiaryIntakeAvailability.accepting;
    final deliveries = deliveriesAsync.asData?.value ?? [];
    final isOffline = availabilityAsync.hasError || deliveriesAsync.hasError;
    final isFullBusy = availability == BeneficiaryIntakeAvailability.fullBusy;

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.location_on, color: cs.primary),
            const SizedBox(width: Spacing.xs),
            Text('SaveAMeal', style: textTheme.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: null,
          ),
          const LogoutButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isOffline) const _OfflineBanner(),
            const SizedBox(height: Spacing.sm),
            Text(
              'CURRENT INTAKE STATUS',
              style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: Spacing.sm),
            IntakeStatusToggle(
              availability: availability,
              onChanged: (newVal) async {
                try {
                  await ref
                      .read(toggleIntakeStatusUseCaseProvider)
                      .call(beneficiaryId: uid, availability: newVal);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Failed to update status. Please try again.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: Spacing.md),
            if (isFullBusy) ...[
              VisibilityInactiveCard(
                variant: VisibilityInactiveVariant.intakePaused,
              ),
              const SizedBox(height: Spacing.md),
            ],
            Text('Active Deliveries', style: textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            if (deliveries.isEmpty)
              const _EmptyDeliveriesState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: deliveries.length,
                itemBuilder: (context, index) {
                  final request = deliveries[index];
                  return ActiveDeliveryCard(
                    request: request,
                    onViewDetails: () => context.push(
                      '/beneficiary/delivery/${request.batchId}',
                    ),
                  );
                },
              ),
            const SizedBox(height: Spacing.md),
            if (isFullBusy) ...[
              VisibilityInactiveCard(
                variant: VisibilityInactiveVariant.visibilityInactive,
              ),
              const SizedBox(height: Spacing.md),
            ],
            const HowPausingWorksSection(),
            const SizedBox(height: Spacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/beneficiary');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Track',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Impact',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
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

class _EmptyDeliveriesState extends StatelessWidget {
  const _EmptyDeliveriesState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delivery_dining, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: Spacing.sm),
          Text(
            'No active deliveries',
            style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
