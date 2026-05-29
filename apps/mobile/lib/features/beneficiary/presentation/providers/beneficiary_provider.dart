import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/beneficiary/data/datasources/intake_remote_datasource.dart';
import 'package:saveameal/features/beneficiary/data/repositories/firestore_intake_repository.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/accept_delivery_job_usecase.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/confirm_delivery_usecase.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/toggle_intake_status_usecase.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/watch_active_deliveries_usecase.dart';
import 'package:saveameal/services/service_providers.dart';

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

// ── Stream providers ───────────────────────────────────────────────────────

/// Active deliveries (open + dispatched) for the current beneficiary.
@riverpod
Stream<List<IntakeRequest>> activeDeliveries(Ref ref, String beneficiaryId) =>
    ref.watch(watchActiveDeliveriesUseCaseProvider).call(beneficiaryId);

/// Single intake request — used by DeliveryDetailScreen.
@riverpod
Stream<IntakeRequest?> intakeRequest(Ref ref, String batchId) =>
    ref.watch(intakeRepositoryProvider).watchIntakeRequest(batchId);

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
