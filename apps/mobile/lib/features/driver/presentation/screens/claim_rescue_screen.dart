import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class ClaimRescueScreen extends ConsumerWidget {
  const ClaimRescueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverState = ref.watch(driverProvider);
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final batch = ref.watch(activeBatchForDriverProvider(uid)).asData?.value;
    final isPickup = driverState.rescuePhase == ClaimRescuePhase.enRoutePickup;

    final statusText = isPickup
        ? 'En Route to Pick-up'
        : 'En Route to Beneficiary';
    final destinationName = isPickup
        ? batch?.donorName ?? '—'
        : batch?.beneficiaryName ?? '—';
    final locationLabel = isPickup ? 'Pick-up Location' : 'Drop-off Location';
    final address = isPickup
        ? batch?.pickupAddress ?? '—'
        : batch?.beneficiaryAddress ?? '—';
    final contactLabel = isPickup ? 'Pick-up Contact' : 'Drop-off Contact';
    final contact = isPickup
        ? (batch?.donorContact ?? 'Ask for staff')
        : 'Ask for shelter staff';
    final cta = isPickup ? 'Arrived at Pick-up' : 'Arrived at Drop-off';
    final description = batch != null && batch.items.isNotEmpty
        ? '${batch.totalPortions}x ${batch.items.first.name}'
        : '${batch?.totalPortions ?? 0}x portions';

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CURRENT DELIVERY',
              style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            Text(
              'Status: $statusText',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: null,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.38,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      batch?.lat ?? 13.7563,
                      batch?.lng ?? 100.5018,
                    ),
                    zoom: 14,
                  ),
                  markers: batch != null
                      ? {
                          Marker(
                            markerId: const MarkerId('dest'),
                            position: LatLng(batch.lat, batch.lng),
                          ),
                        }
                      : {},
                ),
                // TODO(driver): replace with real ETA from Maps Directions API
                Positioned(
                  right: Spacing.sm,
                  bottom: Spacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.sm,
                      vertical: Spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 14, color: cs.primary),
                        const SizedBox(width: Spacing.xs),
                        Text(
                          '~14 min',
                          style: textTheme.labelSmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DESTINATION',
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Icon(Icons.phone_outlined, size: 18, color: cs.primary),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(destinationName, style: textTheme.titleMedium),
                  const SizedBox(height: Spacing.sm),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: locationLabel,
                    value: address,
                  ),
                  const SizedBox(height: Spacing.xs),
                  _InfoRow(
                    icon: Icons.warning_amber_outlined,
                    label: contactLabel,
                    value: contact,
                  ),
                  const Spacer(),
                  if (batch != null)
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Text(description, style: textTheme.bodySmall),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push(
                            '/driver/job/${batch.id}',
                            extra: batch,
                          ),
                          child: Text(
                            'View Details',
                            style: textTheme.labelSmall?.copyWith(
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: Spacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () => _onArrived(context, isPickup),
                      label: Text(cta),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // TODO(driver): wire destinations to router when Impact and Account screens exist
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
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

  void _onArrived(BuildContext context, bool isPickup) {
    if (isPickup) {
      context.push('/driver/pickup-verify');
    } else {
      context.push('/driver/verify-delivery');
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(value, style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
