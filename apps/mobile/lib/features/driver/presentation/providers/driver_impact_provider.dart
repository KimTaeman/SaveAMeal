import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/driver/data/datasources/driver_impact_datasource.dart';
import 'package:saveameal/features/driver/data/repositories/driver_impact_repository_impl.dart';
import 'package:saveameal/features/driver/domain/entities/driver_impact.dart';
import 'package:saveameal/features/driver/domain/entities/leaderboard_entry.dart';
import 'package:saveameal/features/driver/domain/usecases/get_driver_impact_usecase.dart';
import 'package:saveameal/features/driver/domain/usecases/get_leaderboard_usecase.dart';

part 'driver_impact_provider.g.dart';

DriverImpactRepositoryImpl _buildRepo() => DriverImpactRepositoryImpl(
  DriverImpactDatasourceImpl(FirebaseFirestore.instance),
);

@riverpod
Future<DriverImpact> driverImpact(Ref ref, String uid) =>
    GetDriverImpactUsecase(_buildRepo()).call(uid);

@riverpod
Future<List<LeaderboardEntry>> leaderboard(
  Ref ref,
  String uid,
  String period,
) => GetLeaderboardUsecase(_buildRepo()).call(uid, period: period);
