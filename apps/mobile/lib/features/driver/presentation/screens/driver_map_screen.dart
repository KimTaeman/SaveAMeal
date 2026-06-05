import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/core/constants/maps_constants.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/shared/theme/spacing.dart';
// import 'package:saveameal/shared/widgets/logout_button.dart';

class DriverMapScreen extends ConsumerWidget {
  const DriverMapScreen({super.key});

  static const _bangkokCenter = CameraPosition(
    target: LatLng(13.7563, 100.5018),
    zoom: 13,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverState = ref.watch(driverProvider);

    // Guard: redirect whenever this screen renders with an active delivery.
    // Handles tab navigation back to home AND post-login rehydration.
    // Returning early before watching openBatchesProvider prevents Firestore
    // batch-list updates from causing redundant background rebuilds.
    if (driverState.step == DriverStep.claimed ||
        driverState.step == DriverStep.pickedUp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/driver/rescue');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final batchesAsync = ref.watch(openBatchesProvider);
    final batches = batchesAsync.asData?.value ?? [];
    final markers = _buildMarkers(batches, ref);

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
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
            onPressed: () => context.push('/notifications'),
          ),
          // const LogoutButton(),
        ],
      ),
      bottomNavigationBar: _DriverBottomNav(currentIndex: 0),
      body: Stack(
        children: [
          GoogleMap(
            key: const Key('driver_map'),
            mapId: MapsConstants.mapId,
            initialCameraPosition: _bangkokCenter,
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          if (driverState.selectedBatch != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _BatchPreviewCard(
                batch: driverState.selectedBatch!,
                onViewJob: () => context.push(
                  '/driver/job/${driverState.selectedBatch!.id}',
                  extra: driverState.selectedBatch,
                ),
                onDismiss: () =>
                    ref.read(driverProvider.notifier).clearSelection(),
              ),
            ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(List<BatchSummary> batches, WidgetRef ref) {
    return {
      for (final batch in batches)
        Marker(
          markerId: MarkerId(batch.id),
          position: LatLng(batch.lat, batch.lng),
          onTap: () => ref.read(driverProvider.notifier).selectBatch(batch),
        ),
    };
  }
}

class _BatchPreviewCard extends StatelessWidget {
  const _BatchPreviewCard({
    required this.batch,
    required this.onViewJob,
    required this.onDismiss,
  });

  final BatchSummary batch;
  final VoidCallback onViewJob;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Container(
        key: const Key('batch_preview_card'),
        margin: const EdgeInsets.all(Spacing.md),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AVAILABLE PICKUP',
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(batch.donorName, style: textTheme.titleMedium),
                      Text(
                        batch.pickupAddress,
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${batch.totalPortions}\nitems',
                    style: textTheme.labelSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onDismiss),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            if (batch.pickupWindowStart != null)
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    '${batch.pickupWindowStart} – ${batch.pickupWindowEnd}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            const SizedBox(height: Spacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onViewJob,
                child: const Text('View Job →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
