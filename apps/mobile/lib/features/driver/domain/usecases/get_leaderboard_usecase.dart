import 'package:saveameal/features/driver/domain/entities/leaderboard_entry.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_impact_repository.dart';

class GetLeaderboardUsecase {
  const GetLeaderboardUsecase(this._repository);
  final DriverImpactRepository _repository;

  Future<List<LeaderboardEntry>> call(String uid, {required String period}) =>
      _repository.getLeaderboard(uid, period: period);
}
