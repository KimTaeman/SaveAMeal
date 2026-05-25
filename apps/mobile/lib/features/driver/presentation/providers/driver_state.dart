import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';

part 'driver_state.freezed.dart';

enum DriverStep { browsing, claimed, pickedUp, delivered }

enum ClaimRescuePhase { enRoutePickup, enRouteBeneficiary }

@freezed
sealed class DriverState with _$DriverState {
  const factory DriverState({
    BatchSummary? activeBatch,
    BatchSummary? selectedBatch,
    @Default(DriverStep.browsing) DriverStep step,
    @Default(ClaimRescuePhase.enRoutePickup) ClaimRescuePhase rescuePhase,
  }) = _DriverState;
}
