import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/core/logging/app_logger.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/active_delivery_card.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/how_pausing_works_section.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/intake_status_toggle.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/visibility_inactive_card.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class BeneficiaryHomeScreen extends ConsumerStatefulWidget {
  const BeneficiaryHomeScreen({super.key});

  @override
  ConsumerState<BeneficiaryHomeScreen> createState() =>
      _BeneficiaryHomeScreenState();
}

class _BeneficiaryHomeScreenState extends ConsumerState<BeneficiaryHomeScreen> {
  BeneficiaryIntakeAvailability? _optimisticAvailability;

  Future<void> _handleToggle(
    String uid,
    BeneficiaryIntakeAvailability newVal,
  ) async {
    setState(() => _optimisticAvailability = newVal);
    try {
      await ref
          .read(toggleIntakeStatusUseCaseProvider)
          .call(beneficiaryId: uid, availability: newVal);
      // Do NOT clear here — the Firestore stream lags behind the write.
      // Clearing now would revert the UI to the stale stream value before
      // the stream catches up. ref.listen in build() clears it once confirmed.
    } catch (e, st) {
      AppLogger.error('toggleIntakeStatus failed', error: e, stack: st);
      if (mounted) {
        setState(() => _optimisticAvailability = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    final uid = user?.uid ?? '';

    final availabilityAsync = ref.watch(intakeAvailabilityProvider(uid));
    final deliveriesAsync = ref.watch(activeDeliveriesProvider(uid));

    // Once the stream confirms the value we wrote, the optimistic override
    // is no longer needed — drop it so the stream drives the UI from here.
    ref.listen<AsyncValue<BeneficiaryIntakeAvailability>>(
      intakeAvailabilityProvider(uid),
      (_, next) {
        if (_optimisticAvailability != null && next.hasValue) {
          if (mounted) setState(() => _optimisticAvailability = null);
        }
      },
    );

    if (uid.isEmpty ||
        (availabilityAsync.isLoading && !availabilityAsync.hasValue)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final streamAvailability = availabilityAsync.asData?.value;
    final availability =
        _optimisticAvailability ??
        streamAvailability ??
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
              onChanged: (newVal) => _handleToggle(uid, newVal),
            ),
            const SizedBox(height: Spacing.md),
            if (!isFullBusy) ...[
              Container(height: 2, color: cs.primary),
              const SizedBox(height: Spacing.md),
              const _AcceptingStatusCard(),
              const SizedBox(height: Spacing.md),
              const _VisibilityActiveCard(),
              const SizedBox(height: Spacing.md),
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
              const HowPausingWorksSection(),
              const SizedBox(height: Spacing.md),
              const _FacilityImageCard(),
            ] else ...[
              VisibilityInactiveCard(
                variant: VisibilityInactiveVariant.intakePaused,
              ),
              const SizedBox(height: Spacing.md),
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
              VisibilityInactiveCard(
                variant: VisibilityInactiveVariant.visibilityInactive,
              ),
              const SizedBox(height: Spacing.md),
              const HowPausingWorksSection(),
            ],
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

// ── Accepting state widgets ────────────────────────────────────────────────────

class _AcceptingStatusCard extends StatelessWidget {
  const _AcceptingStatusCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.xl,
        ),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: ac.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.eco_outlined, size: 48, color: ac.success),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Accepting Donations',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Your location is currently visible to donors',
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityActiveCard extends StatelessWidget {
  const _VisibilityActiveCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cs.surfaceContainerLow,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: ac.success,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.visibility_outlined, color: ac.success),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Visibility Active',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            'Your facility is currently pinned on the donor map. '
                            'Nearby SaveAMeal members can see your needs.',
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacilityImageCard extends StatelessWidget {
  const _FacilityImageCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            color: cs.surfaceContainerHighest,
            child: Icon(
              Icons.domain,
              size: 72,
              color: cs.onSurfaceVariant.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cs.scrim.withValues(alpha: 0),
                    cs.scrim.withValues(alpha: 0.75),
                  ],
                ),
              ),
              child: Text(
                'Community Shelter',
                style: textTheme.labelLarge?.copyWith(color: cs.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared private widgets ────────────────────────────────────────────────────

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
