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
    // Read user stats and leaderboard in parallel.
    final results = await Future.wait([
      _firestore.collection('users').doc(uid).get(),
      _firestore.collection('leaderboard').doc('thisMonth').get(),
    ]);

    final userSnap = results[0] as DocumentSnapshot;
    final leaderboardSnap = results[1] as DocumentSnapshot;
    final userData = (userSnap.data() as Map<String, dynamic>?) ?? {};
    final leaderboardData = leaderboardSnap.data() as Map<String, dynamic>?;

    // Compute rank from live leaderboard entries.
    final entries = List<Map<String, dynamic>>.from(
      ((leaderboardData?['entries'] as List<dynamic>?) ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    entries.sort(
      (a, b) =>
          ((b['score'] as int?) ?? 0).compareTo((a['score'] as int?) ?? 0),
    );
    final driverIdx = entries.indexWhere((e) => e['uid'] == uid);
    final rank = driverIdx >= 0 ? driverIdx + 1 : 0;
    final totalDrivers = entries.length;

    return DriverImpactModel.fromJson({
      'rank': rank,
      'totalDrivers': totalDrivers,
      'mealsSaved': userData['mealsSaved'] ?? 0,
      'sproutPoints': userData['sproutPoints'] ?? 0,
      'rankProgressCurrent': userData['rankProgressCurrent'] ?? 0,
      'rankProgressTarget': userData['rankProgressTarget'] ?? 100,
      'currentRankName': userData['currentRankName'] ?? 'Bronze',
      'nextRankName': userData['nextRankName'] ?? 'Silver',
    });
  }

  @override
  Future<List<LeaderboardEntryModel>> fetchLeaderboard({
    required String period,
  }) async {
    final doc = await _firestore.collection('leaderboard').doc(period).get();
    final entries = List<Map<String, dynamic>>.from(
      ((doc.data()?['entries'] as List<dynamic>?) ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    // Ensure sorted by score and ranks are sequential.
    entries.sort(
      (a, b) =>
          ((b['score'] as int?) ?? 0).compareTo((a['score'] as int?) ?? 0),
    );
    for (var i = 0; i < entries.length; i++) {
      entries[i]['rank'] = i + 1;
    }
    return entries.map(LeaderboardEntryModel.fromJson).toList();
  }
}
