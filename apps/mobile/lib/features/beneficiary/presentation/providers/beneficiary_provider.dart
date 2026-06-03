import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/beneficiary/data/datasources/intake_remote_datasource.dart';
import 'package:saveameal/features/beneficiary/data/repositories/firestore_intake_repository.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';
import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/accept_delivery_job_usecase.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/confirm_delivery_usecase.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/toggle_intake_status_usecase.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/watch_active_deliveries_usecase.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/watch_intake_request_detail_usecase.dart';
import 'package:saveameal/services/service_providers.dart';
import 'package:saveameal/core/models/driver_location_model.dart';

part 'beneficiary_provider.g.dart';

// ── Dependency injection ───────────────────────────────────────────────────

@riverpod
IntakeRemoteDatasource intakeRemoteDatasource(Ref ref) =>
    IntakeRemoteDatasourceImpl(ref.watch(firestoreServiceProvider));

@riverpod
IntakeRepository intakeRepository(Ref ref) =>
    FirestoreIntakeRepository(ref.watch(intakeRemoteDatasourceProvider));

@riverpod
WatchActiveDeliveriesUseCase watchActiveDeliveriesUseCase(Ref ref) =>
    WatchActiveDeliveriesUseCase(ref.watch(intakeRepositoryProvider));

@riverpod
ToggleIntakeStatusUseCase toggleIntakeStatusUseCase(Ref ref) =>
    ToggleIntakeStatusUseCase(ref.watch(intakeRepositoryProvider));

@riverpod
AcceptDeliveryJobUseCase acceptDeliveryJobUseCase(Ref ref) =>
    AcceptDeliveryJobUseCase(ref.watch(intakeRepositoryProvider));

@riverpod
ConfirmDeliveryUseCase confirmDeliveryUseCase(Ref ref) =>
    ConfirmDeliveryUseCase(ref.watch(intakeRepositoryProvider));

@riverpod
WatchIntakeRequestDetailUseCase watchIntakeRequestDetailUseCase(Ref ref) =>
    WatchIntakeRequestDetailUseCase(ref.watch(intakeRepositoryProvider));

// ── Stream providers ───────────────────────────────────────────────────────

/// Active deliveries (open + dispatched) for the current beneficiary.
@riverpod
Stream<List<IntakeRequest>> activeDeliveries(Ref ref, String beneficiaryId) =>
    ref.watch(watchActiveDeliveriesUseCaseProvider).call(beneficiaryId);

/// Single intake request — used by DeliveryDetailScreen.
@riverpod
Stream<IntakeRequest?> intakeRequest(Ref ref, String batchId) =>
    ref.watch(intakeRepositoryProvider).watchIntakeRequest(batchId);

/// Detail view — item-level batch data for DeliveryDetailScreen.
@riverpod
Stream<IntakeRequestDetail?> intakeRequestDetail(Ref ref, String batchId) =>
    ref.watch(watchIntakeRequestDetailUseCaseProvider).call(batchId);

/// Volunteer queue — all pending batches + this volunteer's dispatched batches.
@riverpod
Stream<List<IntakeRequest>> volunteerQueue(Ref ref, String volunteerId) =>
    ref.watch(intakeRepositoryProvider).watchVolunteerQueue(volunteerId);

/// Beneficiary facility availability toggle state.
@riverpod
Stream<BeneficiaryIntakeAvailability> intakeAvailability(
  Ref ref,
  String beneficiaryId,
) => ref.watch(intakeRepositoryProvider).watchIntakeAvailability(beneficiaryId);

/// Last 3 completed deliveries for a beneficiary — used by RecentDeliveriesSection.
@riverpod
Stream<List<RecentDelivery>> recentDeliveries(Ref ref, String beneficiaryId) =>
    ref.watch(intakeRepositoryProvider).watchRecentDeliveries(beneficiaryId);

/// Live driver position — used by TrackingScreen to move the driver pin.
@riverpod
Stream<DriverLocationModel?> driverLocation(Ref ref, String driverId) =>
    ref.watch(firestoreServiceProvider).watchDriverLocation(driverId);
