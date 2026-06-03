import 'package:saveameal/features/beneficiary/domain/entities/delivery_history_page.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';

/// Number of delivery records fetched per page.
const int kDeliveryHistoryPageSize = 20;

class FetchDeliveryHistoryPageUseCase {
  const FetchDeliveryHistoryPageUseCase(this._repository);

  final IntakeRepository _repository;

  Future<DeliveryHistoryPage> call({
    required String beneficiaryId,
    Object? cursor,
  }) => _repository.fetchDeliveryHistoryPage(
    beneficiaryId: beneficiaryId,
    pageSize: kDeliveryHistoryPageSize,
    cursor: cursor,
  );
}
