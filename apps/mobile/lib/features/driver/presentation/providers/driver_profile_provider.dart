import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/data/datasources/driver_profile_local_datasource.dart';
import 'package:saveameal/features/driver/data/datasources/driver_profile_remote_datasource.dart';
import 'package:saveameal/features/driver/data/repositories/driver_profile_repository_impl.dart';
import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';
import 'package:saveameal/features/driver/domain/usecases/get_driver_profile_usecase.dart';
import 'package:saveameal/features/driver/domain/usecases/update_driver_profile_usecase.dart';
import 'package:saveameal/features/driver/domain/usecases/upload_avatar_usecase.dart';

part 'driver_profile_provider.g.dart';

@riverpod
class DriverProfileNotifier extends _$DriverProfileNotifier {
  late GetDriverProfileUseCase _getProfile;
  late UpdateDriverProfileUseCase _updateProfile;
  late UploadAvatarUseCase _uploadAvatar;
  late DriverProfileRepositoryImpl _repo;

  @override
  Future<DriverProfile?> build() async {
    _repo = DriverProfileRepositoryImpl(
      DriverProfileRemoteDatasourceImpl(
        FirebaseFirestore.instance,
        FirebaseStorage.instance,
      ),
      DriverProfileLocalDatasourceImpl(),
    );
    _getProfile = GetDriverProfileUseCase(_repo);
    _updateProfile = UpdateDriverProfileUseCase(_repo);
    _uploadAvatar = UploadAvatarUseCase(_repo);

    final authAsync = ref.watch(authStateProvider);
    final uid = authAsync.asData?.value?.uid;
    if (uid == null || uid.isEmpty) return null;

    try {
      return await _getProfile(uid);
    } catch (_) {
      return await _repo.getCachedProfile(uid);
    }
  }

  Future<void> updateProfile(DriverProfile profile) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _updateProfile(profile);
      return profile;
    });
  }

  Future<void> uploadAvatar(Uint8List bytes) async {
    final current = state.value;
    if (current == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final url = await _uploadAvatar(current.uid, bytes);
      final updated = current.copyWith(photoUrl: url);
      await _updateProfile(updated);
      return updated;
    });
  }
}
