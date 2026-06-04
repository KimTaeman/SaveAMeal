import 'package:saveameal/features/beneficiary/domain/entities/order_history_entry.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_account_repository.dart';

class WatchOrderHistoryUseCase {
  const WatchOrderHistoryUseCase(this._repository);
  final BeneficiaryAccountRepository _repository;

  Stream<List<OrderHistoryEntry>> call(
    String uid, {
    String? cursor,
    int limit = 10,
  }) => _repository.watchOrderHistory(uid, cursor: cursor, limit: limit);
}
