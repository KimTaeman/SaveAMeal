import 'package:saveameal/features/beneficiary/data/datasources/intake_remote_datasource.dart';
import 'package:saveameal/features/beneficiary/data/models/intake_request_model.dart';
import 'package:saveameal/features/beneficiary/domain/entities/delivery_history_page.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';
import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';
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

  @override
  Stream<IntakeRequestDetail?> watchIntakeRequestDetail(
    String batchId,
    String beneficiaryId,
  ) => _datasource.watchBatch(batchId).map((batch) {
    if (batch == null) return null;
    // Ownership check — reject batches that don't belong to the requesting user.
    if (batch.beneficiaryId != beneficiaryId) return null;
    return batchModelToDetailDomain(batch);
  });

  @override
  Stream<List<RecentDelivery>> watchRecentDeliveries(String beneficiaryId) =>
      _datasource
          .watchRecentDeliveriesForBeneficiary(beneficiaryId)
          .map(
            (batches) => batches
                .map(
                  (b) => RecentDelivery(
                    batchId: b.id,
                    deliveredAt: b.deliveredAt ?? b.updatedAt ?? DateTime.now(),
                    portions: b.items.length,
                    donorName: b.donorName,
                    category: b.items.isNotEmpty
                        ? b.items.first.category
                        : null,
                  ),
                )
                .toList(),
          );

  @override
  Future<void> confirmReceipt({
    required String batchId,
    required String beneficiaryId,
    int? rating,
    String? feedback,
  }) => _datasource.confirmReceipt(
    batchId: batchId,
    rating: rating,
    feedback: feedback,
  );

  @override
  Future<DeliveryHistoryPage> fetchDeliveryHistoryPage({
    required String beneficiaryId,
    required int pageSize,
    Object? cursor,
  }) async {
    final (batches, nextCursor) = await _datasource.fetchDeliveryHistoryPage(
      beneficiaryId: beneficiaryId,
      pageSize: pageSize,
      cursor: cursor,
    );

    final items =
        batches
            .map(
              (b) => RecentDelivery(
                batchId: b.id,
                deliveredAt: b.deliveredAt ?? b.updatedAt ?? DateTime.now(),
                portions: b.items.length,
                donorName: b.donorName,
                // First item's category; null for legacy batches with no items.
                // TODO(future): use majority-category for mixed-category batches.
                category: b.items.isNotEmpty ? b.items.first.category : null,
              ),
            )
            .toList()
          // Sort descending by deliveredAt client-side. The Firestore query omits
          // orderBy to avoid requiring a composite index; sorting here restores the
          // expected date order within each fetched page.
          ..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));

    return DeliveryHistoryPage(
      items: items,
      hasMore: batches.length == pageSize,
      nextCursor: batches.length == pageSize ? nextCursor : null,
    );
  }

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
