import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saveameal/core/models/driver_location_model.dart';
import 'package:saveameal/core/constants/maps_constants.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/services/service_providers.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({
    super.key,
    required this.driverId,
    required this.beneficiaryId,
  });

  final String driverId;
  final String beneficiaryId;

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  static const _driverMarkerId = MarkerId('driver');
  static const _shelterMarkerId = MarkerId('shelter');

  // Bangkok city centre — fallback before shelter coordinates load.
  static const _defaultTarget = LatLng(13.7563, 100.5018);

  LatLng? _shelterLatLng;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadShelterCoordinates();
  }

  Future<void> _loadShelterCoordinates() async {
    final ben = await ref
        .read(firestoreServiceProvider)
        .getBeneficiary(widget.beneficiaryId);
    if (!mounted) return;
    if (ben?.lat != null && ben?.lng != null) {
      setState(() => _shelterLatLng = LatLng(ben!.lat!, ben.lng!));
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(DriverLocationModel? driverLoc) {
    final markers = <Marker>{};
    if (driverLoc != null) {
      markers.add(
        Marker(
          markerId: _driverMarkerId,
          position: LatLng(driverLoc.lat, driverLoc.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Driver'),
        ),
      );
    }
    if (_shelterLatLng != null) {
      markers.add(
        Marker(
          markerId: _shelterMarkerId,
          position: _shelterLatLng!,
          infoWindow: const InfoWindow(title: 'Your Shelter'),
        ),
      );
    }
    return markers;
  }

  LatLng _cameraTarget(DriverLocationModel? driverLoc) {
    if (_shelterLatLng != null) return _shelterLatLng!;
    if (driverLoc != null) return LatLng(driverLoc.lat, driverLoc.lng);
    return _defaultTarget;
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(driverLocationProvider(widget.driverId));

    // Animate camera to show the driver pin when their location updates.
    ref.listen<AsyncValue<DriverLocationModel?>>(
      driverLocationProvider(widget.driverId),
      (_, next) {
        final loc = next.asData?.value;
        if (loc != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(LatLng(loc.lat, loc.lng)),
          );
        }
      },
    );

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final driverLoc = locationAsync.asData?.value;

    final statusText = locationAsync.when(
      data: (loc) =>
          loc != null ? 'Driver is on the way' : 'Waiting for driver location…',
      loading: () => 'Loading…',
      error: (_, e) => 'Unable to load driver location',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Delivery')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              mapId: MapsConstants.mapId,
              initialCameraPosition: CameraPosition(
                target: _cameraTarget(driverLoc),
                zoom: 14,
              ),
              markers: _buildMarkers(driverLoc),
              onMapCreated: (controller) => _mapController = controller,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacing.md),
            color: cs.surfaceContainerLow,
            child: Text(
              statusText,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
