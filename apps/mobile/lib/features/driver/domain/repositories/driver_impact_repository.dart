import 'package:saveameal/features/driver/domain/entities/driver_impact.dart';
import 'package:saveameal/features/driver/domain/entities/leaderboard_entry.dart';

abstract class DriverImpactRepository {
  Future<DriverImpact> getDriverImpact(String uid);
  Future<List<LeaderboardEntry>> getLeaderboard(
    String uid, {
    required String period,
  });
}
