class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.driverName,
    required this.zone,
    required this.score,
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  final int rank;
  final String driverName;
  final String zone;
  final int score;
  final String? avatarUrl;
  final bool isCurrentUser;
}
