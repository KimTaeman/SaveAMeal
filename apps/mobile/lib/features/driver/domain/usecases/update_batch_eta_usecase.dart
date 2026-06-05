// Pure Dart use case — no Flutter or backend imports.
import 'package:saveameal/core/utils/distance_utils.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

class UpdateBatchEtaUsecase {
  const UpdateBatchEtaUsecase(this._repository);

  final DriverRepository _repository;

  /// Computes ETA from [driverLat]/[driverLng] to [destLat]/[destLng] and
  /// writes [estimatedArrivalMinutes] to Firestore only when the integer-minute
  /// value differs from [lastEtaMinutes]. Returns the new ETA on write, or
  /// null when the value was unchanged (no write fired).
  Future<int?> call({
    required String batchId,
    required double driverLat,
    required double driverLng,
    required double destLat,
    required double destLng,
    required int? lastEtaMinutes,
  }) async {
    final newEta = etaMinutes(driverLat, driverLng, destLat, destLng);
    if (newEta == lastEtaMinutes) return null;
    await _repository.updateBatchEta(batchId, newEta);
    return newEta;
  }
}
