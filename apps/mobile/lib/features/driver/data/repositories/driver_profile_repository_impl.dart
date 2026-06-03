import 'package:saveameal/features/driver/data/datasources/driver_profile_local_datasource.dart';
import 'package:saveameal/features/driver/data/datasources/driver_profile_remote_datasource.dart';
import 'package:saveameal/features/driver/data/models/driver_profile_model.dart';
import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_profile_repository.dart';

class DriverProfileRepositoryImpl implements DriverProfileRepository {
  const DriverProfileRepositoryImpl(this._remote, this._local);

  final DriverProfileRemoteDatasourceImpl _remote;
  final DriverProfileLocalDatasourceImpl _local;

  @override
  Future<DriverProfile> getProfile(String uid) async {
    try {
      final model = await _remote.getProfile(uid);
      final entity = model.toEntity();
      await _local.saveProfile(entity);
      return entity;
    } catch (_) {
      final cached = await _local.getProfile(uid);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<void> updateProfile(DriverProfile profile) async {
    await _remote.updateProfile(profile.toModel());
    await _local.saveProfile(profile);
  }

  @override
  Future<String> uploadAvatar(String uid, String localFilePath) =>
      _remote.uploadAvatar(uid, localFilePath);

  @override
  Future<DriverProfile?> getCachedProfile(String uid) => _local.getProfile(uid);
}
