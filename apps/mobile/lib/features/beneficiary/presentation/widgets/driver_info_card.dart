import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saveameal/core/models/driver_location_model.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';
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

    final DriverLocationModel? driverLoc = detail.volunteerId != null
        ? ref.watch(driverLocationProvider(detail.volunteerId!)).asData?.value
        : null;

    final initials = (detail.volunteerName ?? 'V')
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Map section
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: SizedBox(
              height: 200,
              child: Stack(
                children: [
                  // Map or placeholder
                  if (detail.volunteerId != null && driverLoc != null)
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(driverLoc.lat, driverLoc.lng),
                        zoom: 14,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('driver'),
                          position: LatLng(driverLoc.lat, driverLoc.lng),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                        ),
                      },
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
                  // "En route" chip
                  if (driverLoc != null)
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
                          'En route',
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
          // Driver row
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                CircleAvatar(
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
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    detail.volunteerName ?? 'Volunteer',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // ETA column
                if (detail.estimatedArrivalMinutes != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ETA',
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${detail.estimatedArrivalMinutes} min',
                        style: textTheme.titleMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
