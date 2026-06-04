class DriverImpact {
  const DriverImpact({
    required this.rank,
    required this.totalDrivers,
    required this.mealsSaved,
    required this.sproutPoints,
    required this.rankProgressCurrent,
    required this.rankProgressTarget,
    required this.currentRankName,
    required this.nextRankName,
  });

  final int rank;
  final int totalDrivers;
  final int mealsSaved;
  final int sproutPoints;
  final int rankProgressCurrent;
  final int rankProgressTarget;
  final String currentRankName;
  final String nextRankName;

  static const empty = DriverImpact(
    rank: 0,
    totalDrivers: 0,
    mealsSaved: 0,
    sproutPoints: 0,
    rankProgressCurrent: 0,
    rankProgressTarget: 100,
    currentRankName: 'Bronze',
    nextRankName: 'Silver',
  );

  double get rankProgress =>
      rankProgressTarget == 0 ? 0 : rankProgressCurrent / rankProgressTarget;
}
