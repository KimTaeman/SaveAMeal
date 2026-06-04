// Pure Dart — zero Flutter or Firebase imports.

import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';
import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';

abstract class IntakeRepository {
  Stream<List<IntakeRequest>> watchActiveDeliveries(String beneficiaryId);

  Stream<IntakeRequest?> watchIntakeRequest(String batchId);

  Stream<List<IntakeRequest>> watchVolunteerQueue(String volunteerId);

  Future<void> acceptDeliveryJob({
    required String batchId,
    required String volunteerId,
    required String volunteerName,
  });

  Future<void> confirmDelivery({
    required String batchId,
    required String volunteerId,
  });

  Future<void> toggleIntakeStatus({
    required String beneficiaryId,
    required BeneficiaryIntakeAvailability availability,
  });

  Stream<BeneficiaryIntakeAvailability> watchIntakeAvailability(
    String beneficiaryId,
  );

  Stream<IntakeRequestDetail?> watchIntakeRequestDetail(
    String batchId,
    String beneficiaryId,
  );

  Stream<List<RecentDelivery>> watchRecentDeliveries(String beneficiaryId);
}
