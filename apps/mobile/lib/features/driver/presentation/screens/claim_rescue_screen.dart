import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saveameal/core/constants/maps_constants.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:url_launcher/url_launcher.dart';

class ClaimRescueScreen extends ConsumerStatefulWidget {
  const ClaimRescueScreen({super.key});

  @override
  ConsumerState<ClaimRescueScreen> createState() => _ClaimRescueScreenState();
}

class _ClaimRescueScreenState extends ConsumerState<ClaimRescueScreen> {
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSub;
  bool _mapReady = false;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    // google_maps_flutter_web 0.6.2+1 crashes if dispose() is called before
    // onMapCreated fires. Wrap in try/catch and skip on web when not ready.
    if (!kIsWeb || _mapReady) {
      try {
        _mapController?.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    // On web, navigator.permissions reports 'denied' for localhost even when
    // Chrome site settings say 'allow'. Skip the gate on web and let the
    // browser handle permission natively via getCurrentPosition.
    if (!kIsWeb) {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationDenied = true);
        return;
      }
    }

    // One-shot for an immediate first position.
    Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        )
        .then((pos) {
          if (!mounted) return;
          setState(
            () => _currentPosition = LatLng(pos.latitude, pos.longitude),
          );
        })
        .catchError((_) {
          if (mounted) setState(() => _locationDenied = true);
        });

    // Live stream — updates polyline every 10 m of movement on mobile.
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((pos) {
          if (!mounted) return;
          setState(
            () => _currentPosition = LatLng(pos.latitude, pos.longitude),
          );
        }, onError: (_) {});
  }

  Future<void> _openNavigation(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://maps.google.com/maps?daddr=$encoded');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open Maps.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final contact = isPickup ? 'Ask for staff' : 'Ask for shelter staff';
    final cta = isPickup ? 'Arrived at Pick-up' : 'Arrived at Drop-off';
    final description = batch != null && batch.items.isNotEmpty
        ? '${batch.totalPortions}x ${batch.items.first.name}'
        : '${batch?.totalPortions ?? 0}x portions';

    final destLatLng = LatLng(batch?.lat ?? 13.7563, batch?.lng ?? 100.5018);

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final polylines = _currentPosition != null
        ? <Polyline>{
            Polyline(
              polylineId: const PolylineId('route'),
              points: [_currentPosition!, destLatLng],
              color: cs.primary,
              width: 4,
            ),
          }
        : <Polyline>{};

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
            onPressed: () => context.push('/notifications'),
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
                  onMapCreated: (c) {
                    _mapController = c;
                    if (mounted) setState(() => _mapReady = true);
                  },
                  mapId: MapsConstants.mapId,
                  initialCameraPosition: CameraPosition(
                    target: destLatLng,
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  polylines: polylines,
                  markers: {
                    Marker(
                      markerId: const MarkerId('dest'),
                      position: destLatLng,
                    ),
                  },
                ),
                Positioned(
                  right: Spacing.sm,
                  bottom: Spacing.sm,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'navigate',
                        onPressed: address != '—'
                            ? () => _openNavigation(address)
                            : null,
                        backgroundColor: cs.primary,
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Container(
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
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: cs.primary,
                            ),
                            const SizedBox(width: Spacing.xs),
                            Text(
                              _locationDenied
                                  ? 'Location denied'
                                  : _currentPosition != null
                                  ? 'Live route'
                                  : 'Locating…',
                              style: textTheme.labelSmall?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
      bottomNavigationBar: _DriverBottomNav(currentIndex: 0),
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
