import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/core/logging/app_logger.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';

part 'driver_notifier.g.dart';

@riverpod
class DriverNotifier extends _$DriverNotifier {
  Timer? _locationTimer;
  String? _activeDriverId;
  // Cached at build time so _stopTracking can be called safely from onDispose,
  // where ref.read is no longer permitted.
  late DriverRepository _repo;

  @override
  DriverState build() {
    _repo = ref.read(driverRepositoryProvider);
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
    await _repo.claimBatch(batchId, driverId);
    final batch = state.selectedBatch;
    state = state.copyWith(
      step: DriverStep.claimed,
      rescuePhase: ClaimRescuePhase.enRoutePickup,
      selectedBatch: null,
      activeBatch: batch,
    );
    // unawaited — permission dialog must not block the state transition
    unawaited(_startTracking(driverId));
    if (batch != null) {
      AppLogger.info(
        '[Job Accepted]\n'
        '  Driver UID (for seed)      : $driverId\n'
        '  Batch ID (manual QR code) : ${batch.id}\n'
        '  Donor                     : ${batch.donorName}\n'
        '  Pickup                    : ${batch.pickupAddress}\n'
        '  Window                    : ${batch.pickupWindowStart ?? '—'} – ${batch.pickupWindowEnd ?? '—'}\n'
        '  Beneficiary               : ${batch.beneficiaryName}\n'
        '  Drop-off                  : ${batch.beneficiaryAddress}\n'
        '  Portions                  : ${batch.totalPortions}\n'
        '  Instructions              : ${batch.specialInstructions ?? 'none'}',
      );
    }
  }

  Future<void> confirmPickup(String batchId, XFile photoFile) async {
    String photoUrl;
    try {
      photoUrl = await ref
          .read(driverRemoteDatasourceProvider)
          .uploadPickupPhoto(batchId, photoFile);
    } catch (e) {
      AppLogger.warning('Photo upload skipped', error: e);
      photoUrl = photoFile.path;
    }
    await _repo.confirmPickup(batchId, photoUrl);
    state = state.copyWith(
      step: DriverStep.pickedUp,
      rescuePhase: ClaimRescuePhase.enRouteBeneficiary,
    );
  }

  Future<void> confirmDelivery(String batchId, String? notes) async {
    await _repo.confirmDelivery(batchId, notes);
    _stopTracking();
    state = state.copyWith(step: DriverStep.delivered);
  }

  void resetToIdle() {
    state = const DriverState();
  }

  Future<void> _startTracking(String driverId) async {
    _activeDriverId = driverId;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permission denied — tracking disabled');
        return;
      }
    } catch (e) {
      // Platform not available (e.g. in unit tests) — skip tracking gracefully.
      AppLogger.warning('Location permission check unavailable', error: e);
      return;
    }

    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await _repo.upsertLocation(driverId, pos.latitude, pos.longitude);
      } on PermissionDeniedException {
        AppLogger.warning('Location permission denied — stopping tracking');
        _stopTracking();
      } catch (e) {
        AppLogger.warning('Location write failed', error: e);
      }
    });
  }

  void _stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    if (_activeDriverId != null) {
      _repo
          .deleteLocation(_activeDriverId!)
          .catchError(
            (Object e) =>
                AppLogger.warning('Location cleanup failed', error: e),
          );
      _activeDriverId = null;
    }
  }
}
