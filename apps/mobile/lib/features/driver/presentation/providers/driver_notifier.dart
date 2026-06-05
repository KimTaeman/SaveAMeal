import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/core/logging/app_logger.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/domain/usecases/update_batch_eta_usecase.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';

part 'driver_notifier.g.dart';

@riverpod
class DriverNotifier extends _$DriverNotifier {
  Timer? _locationTimer;
  String? _activeDriverId;
  String? _activeBatchId;
  double? _destLat;
  double? _destLng;
  int? _lastEtaMinutes;
  // Beneficiary coords cached from the active-batch stream (written to Firestore
  // by the claimBatch transaction). Used in confirmPickup to switch the ETA
  // destination without a ref.read on a stream provider.
  double? _beneficiaryLat;
  double? _beneficiaryLng;
  StreamSubscription<BatchSummary?>? _activeBatchSub;
  // Cached at build time so _stopTracking can be called safely from onDispose,
  // where ref.read is no longer permitted.
  late DriverRepository _repo;
  late UpdateBatchEtaUsecase _etaUsecase;

  @override
  DriverState build() {
    _repo = ref.read(driverRepositoryProvider);
    _etaUsecase = ref.read(updateBatchEtaUsecaseProvider);
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
    // Initial ETA destination is the pickup location.
    _activeBatchId = batchId;
    _destLat = batch?.lat;
    _destLng = batch?.lng;
    _lastEtaMinutes = null;
    // Subscribe to the active-batch stream to cache beneficiary delivery coords
    // as soon as the claimBatch transaction propagates them from Firestore.
    _beneficiaryLat = null;
    _beneficiaryLng = null;
    _activeBatchSub?.cancel();
    _activeBatchSub = _repo.getActiveBatch(driverId).listen((b) {
      if (b != null && b.beneficiaryLat != null && b.beneficiaryLng != null) {
        _beneficiaryLat = b.beneficiaryLat;
        _beneficiaryLng = b.beneficiaryLng;
      }
    });
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
    // Switch ETA destination to beneficiary delivery coordinates (cached from
    // the active-batch stream subscription started in claimBatch).
    if (_beneficiaryLat != null && _beneficiaryLng != null) {
      _destLat = _beneficiaryLat;
      _destLng = _beneficiaryLng;
      _lastEtaMinutes = null;
    } else {
      AppLogger.warning(
        'confirmPickup: beneficiary coordinates unavailable — ETA destination not updated',
      );
    }
  }

  Future<void> confirmDelivery(String batchId, String? notes) async {
    await _repo.confirmDelivery(batchId, notes);
    _stopTracking();
    state = state.copyWith(step: DriverStep.delivered);
  }

  void resetToIdle() {
    _stopTracking();
    state = const DriverState();
  }

  // For testing only — allows tests to simulate a started tracking session
  // without triggering platform-dependent Geolocator calls.
  @visibleForTesting
  void setActiveDriverIdForTest(String driverId) {
    _activeDriverId = driverId;
  }

  // For testing only — exposes the current ETA destination so tests can verify
  // that confirmPickup correctly switches from pickup to beneficiary coordinates.
  @visibleForTesting
  (double?, double?) get etaDestinationForTest => (_destLat, _destLng);

  Future<void> _startTracking(String driverId) async {
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

    // Set only after permission is confirmed — avoids spurious deleteLocation
    // calls if permission was denied.
    _activeDriverId = driverId;

    // One-shot initial position fix to publish location and seed the ETA
    // before the first 30-second timer tick fires.
    try {
      final initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _repo.upsertLocation(
        driverId,
        initialPos.latitude,
        initialPos.longitude,
      );
      unawaited(_writeEtaIfChanged(initialPos.latitude, initialPos.longitude));
    } catch (e) {
      AppLogger.warning('Initial location fix failed', error: e);
    }

    // Guard: if disposed while awaiting the initial position fix, don't start
    // the timer — it would be impossible to cancel and would leak.
    if (_activeDriverId == null) return;

    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await _repo.upsertLocation(driverId, pos.latitude, pos.longitude);
        unawaited(_writeEtaIfChanged(pos.latitude, pos.longitude));
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
    _activeBatchSub?.cancel();
    _activeBatchSub = null;
    if (_activeDriverId != null) {
      _repo
          .deleteLocation(_activeDriverId!)
          .catchError(
            (Object e) =>
                AppLogger.warning('Location cleanup failed', error: e),
          );
      _activeDriverId = null;
    }
    _activeBatchId = null;
    _destLat = null;
    _destLng = null;
    _lastEtaMinutes = null;
    _beneficiaryLat = null;
    _beneficiaryLng = null;
  }

  Future<void> _writeEtaIfChanged(double driverLat, double driverLng) async {
    // Capture field values locally — avoids a TOCTOU race if _stopTracking
    // fires between the null-check and the async write.
    final batchId = _activeBatchId;
    final destLat = _destLat;
    final destLng = _destLng;
    if (batchId == null || destLat == null || destLng == null) return;
    try {
      final newEta = await _etaUsecase.call(
        batchId: batchId,
        driverLat: driverLat,
        driverLng: driverLng,
        destLat: destLat,
        destLng: destLng,
        lastEtaMinutes: _lastEtaMinutes,
      );
      if (newEta != null) _lastEtaMinutes = newEta;
    } catch (e) {
      AppLogger.warning('ETA update failed', error: e);
    }
  }
}
