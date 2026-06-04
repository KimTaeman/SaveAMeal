import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:saveameal/features/driver/domain/entities/leaderboard_entry.dart';

part 'leaderboard_entry_model.freezed.dart';
part 'leaderboard_entry_model.g.dart';

@freezed
sealed class LeaderboardEntryModel with _$LeaderboardEntryModel {
  const factory LeaderboardEntryModel({
    required int rank,
    required String driverName,
    required String zone,
    required String uid,
    required int score,
    String? avatarUrl,
  }) = _LeaderboardEntryModel;

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryModelFromJson(json);
}

extension LeaderboardEntryModelX on LeaderboardEntryModel {
  LeaderboardEntry toEntity(String currentUid) => LeaderboardEntry(
    rank: rank,
    driverName: driverName,
    zone: zone,
    score: score,
    avatarUrl: avatarUrl,
    isCurrentUser: uid == currentUid,
  );
}
