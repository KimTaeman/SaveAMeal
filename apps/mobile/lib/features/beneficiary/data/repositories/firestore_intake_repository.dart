import 'package:saveameal/features/beneficiary/data/datasources/intake_remote_datasource.dart';
import 'package:saveameal/features/beneficiary/data/models/intake_request_model.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';

class FirestoreIntakeRepository implements IntakeRepository {
  const FirestoreIntakeRepository(this._datasource);

  final IntakeRemoteDatasource _datasource;

  @override
  Stream<List<IntakeRequest>> watchActiveDeliveries(String beneficiaryId) =>
      _datasource
          .watchActiveDeliveriesForBeneficiary(beneficiaryId)
          .map(
            (batches) => batches
                .map((b) => IntakeRequestModel.fromBatch(b).toDomain())
                .toList(),
          );

  @override
  Stream<IntakeRequest?> watchIntakeRequest(String batchId) => _datasource
      .watchBatch(batchId)
      .map(
        (batch) => batch == null
            ? null
            : IntakeRequestModel.fromBatch(batch).toDomain(),
      );

  @override
  Stream<List<IntakeRequest>> watchVolunteerQueue(String volunteerId) =>
      _datasource
          .watchVolunteerQueue(volunteerId)
          .map(
            (batches) => batches
                .map((b) => IntakeRequestModel.fromBatch(b).toDomain())
                .toList(),
          );

  @override
  Future<void> acceptDeliveryJob({
    required String batchId,
    required String volunteerId,
    required String volunteerName,
  }) => _datasource.acceptJob(
    batchId: batchId,
    volunteerId: volunteerId,
    volunteerName: volunteerName,
  );

  @override
  Future<void> confirmDelivery({
    required String batchId,
    required String volunteerId,
  }) => _datasource.confirmDelivery(batchId: batchId, volunteerId: volunteerId);

  @override
  Future<void> toggleIntakeStatus({
    required String beneficiaryId,
    required BeneficiaryIntakeAvailability availability,
  }) => _datasource.setIntakeAvailability(
    beneficiaryId: beneficiaryId,
    intakeStatus: _availabilityToString(availability),
  );

  @override
  Stream<BeneficiaryIntakeAvailability> watchIntakeAvailability(
    String beneficiaryId,
  ) => _datasource
      .watchIntakeAvailability(beneficiaryId)
      .map(_stringToAvailability);

  static String _availabilityToString(BeneficiaryIntakeAvailability a) =>
      switch (a) {
        BeneficiaryIntakeAvailability.accepting => 'accepting',
        BeneficiaryIntakeAvailability.fullBusy => 'full',
      };

  static BeneficiaryIntakeAvailability _stringToAvailability(String s) =>
      s == 'full'
      ? BeneficiaryIntakeAvailability.fullBusy
      : BeneficiaryIntakeAvailability.accepting;
}
