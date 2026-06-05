import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saveameal/core/models/driver_location_model.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';
import 'package:saveameal/core/constants/maps_constants.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class DriverInfoCard extends ConsumerWidget {
  const DriverInfoCard({super.key, required this.detail});

  final IntakeRequestDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    // Watch the location stream only when a driver is assigned; short-circuit
    // to null when there is no volunteerId so the provider is never subscribed.
    final AsyncValue<DriverLocationModel?>? locationAsync =
        detail.volunteerId != null
        ? ref.watch(driverLocationProvider(detail.volunteerId!))
        : null;
    final DriverLocationModel? driverLoc = locationAsync?.asData?.value;

    // Bangkok city centre — fallback camera target before location loads.
    const defaultTarget = LatLng(13.7563, 100.5018);

    final initials = (detail.volunteerName ?? 'V')
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();
    final eta = detail.estimatedArrivalMinutes?.clamp(1, 600);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Map section — labelled for screen readers; inner decorative widgets
          // are excluded so TalkBack/VoiceOver reads one coherent description.
          Semantics(
            label: detail.volunteerId == null
                ? 'Driver location unavailable — no driver assigned'
                : driverLoc != null
                ? 'Driver location map — driver is en route'
                : 'Driver location map — locating driver',
            excludeSemantics: true,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Live map whenever a driver is assigned; placeholder
                    // otherwise (e.g. open/pending batches with no volunteer).
                    if (detail.volunteerId != null)
                      GoogleMap(
                        mapId: MapsConstants.mapId,
                        initialCameraPosition: CameraPosition(
                          target: driverLoc != null
                              ? LatLng(driverLoc.lat, driverLoc.lng)
                              : defaultTarget,
                          zoom: 14,
                        ),
                        markers: driverLoc != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('driver'),
                                  position: LatLng(
                                    driverLoc.lat,
                                    driverLoc.lng,
                                  ),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueAzure,
                                  ),
                                ),
                              }
                            : const {},
                        liteModeEnabled: true,
                        zoomGesturesEnabled: false,
                        scrollGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      )
                    else
                      Container(
                        color: cs.surfaceContainerHigh,
                        child: Center(
                          child: Icon(
                            Icons.local_shipping_outlined,
                            color: cs.onSurfaceVariant,
                            size: 40,
                          ),
                        ),
                      ),
                    // Status chip — always visible once a driver is assigned.
                    if (detail.volunteerId != null)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: 4,
                          ),
                          child: Text(
                            driverLoc != null ? 'En route' : 'Locating driver…',
                            style: textTheme.labelSmall?.copyWith(
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Driver row
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                // Decorative avatar — name Text adjacent is the readable label.
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: ac.success.withValues(alpha: 0.15),
                    child: Text(
                      initials,
                      style: textTheme.labelMedium?.copyWith(
                        color: ac.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    detail.volunteerName ?? 'Volunteer',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // ETA — merge the two-line label into one screen-reader string.
                if (eta != null)
                  Semantics(
                    label: 'ETA: $eta minutes',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'ETA',
                          style: textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '$eta min',
                          style: textTheme.titleMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'ETA unknown',
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
