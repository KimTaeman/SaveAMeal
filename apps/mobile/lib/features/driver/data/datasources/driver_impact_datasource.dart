import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saveameal/features/driver/data/models/driver_impact_model.dart';
import 'package:saveameal/features/driver/data/models/leaderboard_entry_model.dart';

abstract class DriverImpactDatasource {
  Future<DriverImpactModel> fetchDriverImpact(String uid);
  Future<List<LeaderboardEntryModel>> fetchLeaderboard({
    required String period,
  });
}

class DriverImpactDatasourceImpl implements DriverImpactDatasource {
  const DriverImpactDatasourceImpl(this._firestore);
  final FirebaseFirestore _firestore;

  @override
  Future<DriverImpactModel> fetchDriverImpact(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    return DriverImpactModel.fromJson({
      'rank': data['rank'] ?? 0,
      'totalDrivers': data['totalDrivers'] ?? 0,
      'mealsSaved': data['mealsSaved'] ?? 0,
      'sproutPoints': data['sproutPoints'] ?? 0,
      'rankProgressCurrent': data['rankProgressCurrent'] ?? 0,
      'rankProgressTarget': data['rankProgressTarget'] ?? 100,
      'currentRankName': data['currentRankName'] ?? 'Bronze',
      'nextRankName': data['nextRankName'] ?? 'Silver',
    });
  }

  @override
  Future<List<LeaderboardEntryModel>> fetchLeaderboard({
    required String period,
  }) async {
    final doc = await _firestore.collection('leaderboard').doc(period).get();
    final entries = (doc.data()?['entries'] as List<dynamic>?) ?? [];
    return entries
        .cast<Map<String, dynamic>>()
        .map(LeaderboardEntryModel.fromJson)
        .toList();
  }
}
