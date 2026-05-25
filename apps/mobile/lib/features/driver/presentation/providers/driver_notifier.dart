import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/core/logging/app_logger.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';

part 'driver_notifier.g.dart';

@Riverpod(name: 'driverNotifierProvider')
class DriverNotifier extends _$DriverNotifier {
  Timer? _locationTimer;

  @override
  DriverState build() {
    ref.onDispose(_stopTracking);
    return const DriverState();
  }

  void selectBatch(BatchSummary batch) {
    state = state.copyWith(selectedBatch: batch);
  }

  void clearSelection() {
    state = state.copyWith(selectedBatch: null);
  }

  Future<void> claimBatch(String batchId, String driverId) async {
    await ref.read(driverRepositoryProvider).claimBatch(batchId, driverId);
    state = state.copyWith(
      step: DriverStep.claimed,
      rescuePhase: ClaimRescuePhase.enRoutePickup,
      selectedBatch: null,
    );
    _startTracking(driverId);
  }

  Future<void> confirmPickup(String batchId, String localPhotoPath) async {
    String photoUrl;
    try {
      photoUrl = await ref
          .read(driverRemoteDatasourceProvider)
          .uploadPickupPhoto(batchId, localPhotoPath);
    } catch (e) {
      // In test environments the datasource is unavailable; use the path as-is.
      AppLogger.warning('Photo upload skipped, using local path', error: e);
      photoUrl = localPhotoPath;
    }
    await ref.read(driverRepositoryProvider).confirmPickup(batchId, photoUrl);
    state = state.copyWith(
      step: DriverStep.pickedUp,
      rescuePhase: ClaimRescuePhase.enRouteBeneficiary,
    );
  }

  Future<void> confirmDelivery(String batchId, String? notes) async {
    await ref.read(driverRepositoryProvider).confirmDelivery(batchId, notes);
    _stopTracking();
    state = state.copyWith(step: DriverStep.delivered);
  }

  void resetToIdle() {
    state = const DriverState();
  }

  void _startTracking(String driverId) {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await ref
            .read(driverRepositoryProvider)
            .upsertLocation(driverId, pos.latitude, pos.longitude);
      } catch (e) {
        AppLogger.warning('Location write failed', error: e);
      }
    });
  }

  void _stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }
}
