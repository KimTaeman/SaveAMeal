import 'package:saveameal/features/driver/data/datasources/driver_impact_datasource.dart';
import 'package:saveameal/features/driver/data/models/driver_impact_model.dart';
import 'package:saveameal/features/driver/data/models/leaderboard_entry_model.dart';
import 'package:saveameal/features/driver/domain/entities/driver_impact.dart';
import 'package:saveameal/features/driver/domain/entities/leaderboard_entry.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_impact_repository.dart';

class DriverImpactRepositoryImpl implements DriverImpactRepository {
  const DriverImpactRepositoryImpl(this._datasource);
  final DriverImpactDatasource _datasource;

  @override
  Future<DriverImpact> getDriverImpact(String uid) async {
    final model = await _datasource.fetchDriverImpact(uid);
    return model.toEntity();
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard(
    String uid, {
    required String period,
  }) async {
    final models = await _datasource.fetchLeaderboard(period: period);
    return models.map((m) => m.toEntity(uid)).toList();
  }
}
