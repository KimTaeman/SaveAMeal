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
    final batchAsync = ref.watch(activeBatchForDriverProvider(uid));
    final batch = batchAsync.asData?.value;
    final isEnRoutePickup =
        driverState.rescuePhase == ClaimRescuePhase.enRoutePickup;

    final destination = isEnRoutePickup
        ? batch?.pickupAddress ?? '—'
        : batch?.beneficiaryAddress ?? '—';
    final destinationName = isEnRoutePickup
        ? batch?.donorName ?? '—'
        : batch?.beneficiaryName ?? '—';
    final cta = isEnRoutePickup
        ? 'Arrived at Pick-up'
        : 'Arrived at Beneficiary';

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(batch?.lat ?? 13.7563, batch?.lng ?? 100.5018),
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
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESTINATION',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  destinationName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: Spacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Expanded(
                      child: Text(
                        destination,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                if (batch != null) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    '${batch.totalPortions}x portions · ${batch.donorName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: Spacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _onArrived(context, isEnRoutePickup),
                    child: Text(cta),
                  ),
                ),
              ],
            ),
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
