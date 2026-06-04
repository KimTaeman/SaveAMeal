import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/domain/entities/delivery_history_page.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_item.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';
import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/watch_intake_request_detail_usecase.dart';

// Handwritten fake — avoids the mockito/build_runner dependency.
class _FakeIntakeRepository implements IntakeRepository {
  Stream<IntakeRequestDetail?> Function(String batchId, String beneficiaryId)?
  _watchDetail;

  void stubWatchDetail(
    Stream<IntakeRequestDetail?> Function(String, String) fn,
  ) {
    _watchDetail = fn;
  }

  @override
  Stream<IntakeRequestDetail?> watchIntakeRequestDetail(
    String batchId,
    String beneficiaryId,
  ) {
    if (_watchDetail != null) return _watchDetail!(batchId, beneficiaryId);
    throw UnimplementedError();
  }

  @override
  Stream<List<IntakeRequest>> watchActiveDeliveries(String beneficiaryId) =>
      throw UnimplementedError();

  @override
  Stream<IntakeRequest?> watchIntakeRequest(String batchId) =>
      throw UnimplementedError();

  @override
  Stream<List<IntakeRequest>> watchVolunteerQueue(String volunteerId) =>
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
  Stream<BeneficiaryIntakeAvailability> watchIntakeAvailability(
    String beneficiaryId,
  ) => throw UnimplementedError();

  @override
  Stream<List<RecentDelivery>> watchRecentDeliveries(String beneficiaryId) =>
      throw UnimplementedError();

  @override
  Future<DeliveryHistoryPage> fetchDeliveryHistoryPage({
    required String beneficiaryId,
    required int pageSize,
    Object? cursor,
  }) => throw UnimplementedError();
}

void main() {
  late _FakeIntakeRepository fakeRepository;
  late WatchIntakeRequestDetailUseCase useCase;

  setUp(() {
    fakeRepository = _FakeIntakeRepository();
    useCase = WatchIntakeRequestDetailUseCase(fakeRepository);
  });

  const batchId = 'batch_001';
  const beneficiaryId = 'ben_001';

  final fakeDetail = IntakeRequestDetail(
    batchId: batchId,
    beneficiaryId: beneficiaryId,
    donorId: 'donor_001',
    status: IntakeStatus.dispatched,
    portions: 1,
    weightKg: 5.0,
    items: [IntakeItem(name: 'pork', category: 'meat', weightKg: 5.0)],
  );

  group('WatchIntakeRequestDetailUseCase', () {
    test('delegates to repository.watchIntakeRequestDetail', () {
      fakeRepository.stubWatchDetail((b, id) => Stream.value(fakeDetail));

      final stream = useCase.call(batchId, beneficiaryId);

      expect(stream, emits(fakeDetail));
    });

    test('passes through null when repository emits null', () {
      fakeRepository.stubWatchDetail((b, id) => Stream.value(null));

      expect(useCase.call(batchId, beneficiaryId), emits(null));
    });
  });
}
