import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/domain/entities/delivery_history_page.dart';
import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/fetch_delivery_history_page_usecase.dart';

// Minimal hand-rolled fake — no Mockito/Mocktail to avoid build_runner test dep.
class _FakeIntakeRepository extends Fake implements IntakeRepository {
  String? lastBeneficiaryId;
  int? lastPageSize;
  Object? lastCursor;
  DeliveryHistoryPage Function(String, int, Object?)? onFetchPage;

  @override
  Future<DeliveryHistoryPage> fetchDeliveryHistoryPage({
    required String beneficiaryId,
    required int pageSize,
    Object? cursor,
  }) async {
    lastBeneficiaryId = beneficiaryId;
    lastPageSize = pageSize;
    lastCursor = cursor;
    return onFetchPage?.call(beneficiaryId, pageSize, cursor) ??
        const DeliveryHistoryPage(items: [], hasMore: false);
  }
}

void main() {
  late _FakeIntakeRepository repository;
  late FetchDeliveryHistoryPageUseCase useCase;

  setUp(() {
    repository = _FakeIntakeRepository();
    useCase = FetchDeliveryHistoryPageUseCase(repository);
  });

  test('delegates to repository with correct beneficiaryId and pageSize, '
      'cursor null on first call', () async {
    await useCase(beneficiaryId: 'ben_001');

    expect(repository.lastBeneficiaryId, 'ben_001');
    expect(repository.lastPageSize, kDeliveryHistoryPageSize);
    expect(repository.lastCursor, isNull);
  });

  test('forwards cursor to repository on subsequent call', () async {
    const fakeCursor = 'cursor_token_xyz';

    await useCase(beneficiaryId: 'ben_001', cursor: fakeCursor);

    expect(repository.lastCursor, fakeCursor);
  });

  test('returns DeliveryHistoryPage unchanged from repository', () async {
    final delivery = RecentDelivery(
      batchId: 'batch_abc123',
      deliveredAt: DateTime(2024, 1, 15),
      portions: 10,
      donorName: 'Test Donor',
    );
    final expectedPage = DeliveryHistoryPage(
      items: [delivery],
      hasMore: true,
      nextCursor: 'next_cursor',
    );

    repository.onFetchPage = (a, b, c) => expectedPage;

    final result = await useCase(beneficiaryId: 'ben_001');

    expect(result.items, equals(expectedPage.items));
    expect(result.hasMore, equals(expectedPage.hasMore));
    expect(result.nextCursor, equals(expectedPage.nextCursor));
  });
}
