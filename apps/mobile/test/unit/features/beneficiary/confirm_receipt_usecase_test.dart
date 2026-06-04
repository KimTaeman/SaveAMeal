import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/domain/entities/delivery_history_page.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';
import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/confirm_receipt_usecase.dart';

class _FakeIntakeRepository implements IntakeRepository {
  String? capturedBatchId;
  String? capturedBeneficiaryId;
  int? capturedRating;
  String? capturedFeedback;
  Exception? throwOnConfirm;

  @override
  Future<void> confirmReceipt({
    required String batchId,
    required String beneficiaryId,
    int? rating,
    String? feedback,
  }) async {
    if (throwOnConfirm != null) throw throwOnConfirm!;
    capturedBatchId = batchId;
    capturedBeneficiaryId = beneficiaryId;
    capturedRating = rating;
    capturedFeedback = feedback;
  }

  @override
  Stream<List<IntakeRequest>> watchActiveDeliveries(String b) =>
      throw UnimplementedError();

  @override
  Stream<IntakeRequest?> watchIntakeRequest(String b) =>
      throw UnimplementedError();

  @override
  Stream<List<IntakeRequest>> watchVolunteerQueue(String v) =>
      throw UnimplementedError();

  @override
  Future<void> acceptDeliveryJob({
    required String batchId,
    required String volunteerId,
    required String volunteerName,
  }) => throw UnimplementedError();

  @override
  Future<void> confirmDelivery({
    required String batchId,
    required String volunteerId,
  }) => throw UnimplementedError();

  @override
  Future<void> toggleIntakeStatus({
    required String beneficiaryId,
    required BeneficiaryIntakeAvailability availability,
  }) => throw UnimplementedError();

  @override
  Stream<BeneficiaryIntakeAvailability> watchIntakeAvailability(String b) =>
      throw UnimplementedError();

  @override
  Stream<IntakeRequestDetail?> watchIntakeRequestDetail(
    String batchId,
    String beneficiaryId,
  ) => throw UnimplementedError();

  @override
  Stream<List<RecentDelivery>> watchRecentDeliveries(String b) =>
      throw UnimplementedError();

  @override
  Future<DeliveryHistoryPage> fetchDeliveryHistoryPage({
    required String beneficiaryId,
    required int pageSize,
    Object? cursor,
  }) => throw UnimplementedError();
}

void main() {
  group('ConfirmReceiptUseCase', () {
    // (1) call delegates to IntakeRepository.confirmReceipt with exact args
    test(
      'delegates to IntakeRepository.confirmReceipt with exact args',
      () async {
        final fakeRepo = _FakeIntakeRepository();
        final useCase = ConfirmReceiptUseCase(fakeRepo);

        await useCase.call(
          batchId: 'batch_123',
          beneficiaryId: 'ben_456',
          rating: 4,
          feedback: 'Great delivery!',
        );

        expect(fakeRepo.capturedBatchId, 'batch_123');
        expect(fakeRepo.capturedBeneficiaryId, 'ben_456');
        expect(fakeRepo.capturedRating, 4);
        expect(fakeRepo.capturedFeedback, 'Great delivery!');
      },
    );

    // (2) propagates exception thrown by the mock repository
    test('propagates exception thrown by repository', () async {
      final fakeRepo = _FakeIntakeRepository()
        ..throwOnConfirm = Exception('Firestore error');
      final useCase = ConfirmReceiptUseCase(fakeRepo);

      await expectLater(
        () => useCase.call(batchId: 'batch_123', beneficiaryId: 'ben_456'),
        throwsA(isA<Exception>()),
      );
    });

    // (3) passes rating: null and feedback: null when both are omitted
    test('passes rating: null and feedback: null when omitted', () async {
      final fakeRepo = _FakeIntakeRepository();
      final useCase = ConfirmReceiptUseCase(fakeRepo);

      await useCase.call(batchId: 'batch_abc', beneficiaryId: 'ben_xyz');

      expect(fakeRepo.capturedRating, isNull);
      expect(fakeRepo.capturedFeedback, isNull);
    });
  });
}
