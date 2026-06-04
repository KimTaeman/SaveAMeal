import 'package:saveameal/core/models/batch_model.dart';
import 'package:saveameal/services/firestore_service.dart';

abstract class IntakeRemoteDatasource {
  Stream<List<BatchModel>> watchActiveDeliveriesForBeneficiary(
    String beneficiaryId,
  );

  Stream<BatchModel?> watchBatch(String batchId);

  Stream<List<BatchModel>> watchVolunteerQueue(String volunteerId);

  Future<void> acceptJob({
    required String batchId,
    required String volunteerId,
    required String volunteerName,
  });

  Future<void> confirmDelivery({
    required String batchId,
    required String volunteerId,
  });

  Future<void> setIntakeAvailability({
    required String beneficiaryId,
    required String intakeStatus,
  });

  Stream<String> watchIntakeAvailability(String beneficiaryId);

  Stream<List<BatchModel>> watchRecentDeliveriesForBeneficiary(
    String beneficiaryId,
  );

  /// Returns (items, lastDocumentSnapshot?) for cursor advancement.
  /// The raw DocumentSnapshot is returned as Object? to avoid exposing
  /// cloud_firestore types outside the datasource layer.
  Future<(List<BatchModel>, Object? nextCursor)> fetchDeliveryHistoryPage({
    required String beneficiaryId,
    required int pageSize,
    Object? cursor,
  });
}

class IntakeRemoteDatasourceImpl implements IntakeRemoteDatasource {
  const IntakeRemoteDatasourceImpl(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Stream<List<BatchModel>> watchActiveDeliveriesForBeneficiary(
    String beneficiaryId,
  ) => _firestoreService.watchActiveDeliveriesForBeneficiary(beneficiaryId);

  @override
  Stream<BatchModel?> watchBatch(String batchId) =>
      _firestoreService.watchBatch(batchId);

  @override
  Stream<List<BatchModel>> watchVolunteerQueue(String volunteerId) =>
      _firestoreService.watchVolunteerQueue(volunteerId);

  @override
  Future<void> acceptJob({
    required String batchId,
    required String volunteerId,
    required String volunteerName,
  }) => _firestoreService.acceptJob(
    batchId: batchId,
    volunteerId: volunteerId,
    volunteerName: volunteerName,
  );

  @override
  Future<void> confirmDelivery({
    required String batchId,
    required String volunteerId,
  }) => _firestoreService.confirmDelivery(batchId, null);

  @override
  Future<void> setIntakeAvailability({
    required String beneficiaryId,
    required String intakeStatus,
  }) => _firestoreService.setIntakeAvailability(
    beneficiaryId: beneficiaryId,
    intakeStatus: intakeStatus,
  );

  @override
  Stream<String> watchIntakeAvailability(String beneficiaryId) =>
      _firestoreService.watchIntakeAvailability(beneficiaryId);

  @override
  Stream<List<BatchModel>> watchRecentDeliveriesForBeneficiary(
    String beneficiaryId,
  ) => _firestoreService.watchRecentDeliveriesForBeneficiary(beneficiaryId);

  @override
  Future<(List<BatchModel>, Object? nextCursor)> fetchDeliveryHistoryPage({
    required String beneficiaryId,
    required int pageSize,
    Object? cursor,
  }) => _firestoreService.fetchDeliveryHistoryPage(
    beneficiaryId: beneficiaryId,
    pageSize: pageSize,
    cursor: cursor,
  );
}
