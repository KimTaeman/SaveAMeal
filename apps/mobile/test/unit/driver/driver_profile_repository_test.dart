import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/data/datasources/driver_profile_local_datasource.dart';
import 'package:saveameal/features/driver/data/datasources/driver_profile_remote_datasource.dart';
import 'package:saveameal/features/driver/data/models/driver_profile_model.dart';
import 'package:saveameal/features/driver/data/repositories/driver_profile_repository_impl.dart';
import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────────

class _FakeRemote implements DriverProfileRemoteDatasourceImpl {
  _FakeRemote({this.profile, this.shouldThrow = false});
  final DriverProfileModel? profile;
  final bool shouldThrow;

  @override
  Future<DriverProfileModel> getProfile(String uid) async {
    if (shouldThrow) throw Exception('Network error');
    return profile!;
  }

  @override
  Future<void> updateProfile(DriverProfileModel model) async {}

  @override
  Future<String> uploadAvatar(String uid, String localFilePath) async =>
      'https://example.com/avatar.jpg';
}

class _FakeLocal implements DriverProfileLocalDatasourceImpl {
  _FakeLocal({this.cachedProfile});
  final DriverProfile? cachedProfile;
  DriverProfile? _saved;

  @override
  Future<DriverProfile?> getProfile(String uid) async =>
      _saved ?? cachedProfile;

  @override
  Future<void> saveProfile(DriverProfile profile) async {
    _saved = profile;
  }
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  const testModel = DriverProfileModel(
    uid: 'uid-1',
    name: 'Test Driver',
    email: 'test@driver.com',
    phone: '+66 812 000 000',
  );

  const testEntity = DriverProfile(
    uid: 'uid-1',
    name: 'Test Driver',
    email: 'test@driver.com',
    phone: '+66 812 000 000',
  );

  group('DriverProfileRepositoryImpl', () {
    test('getProfile returns remote data and caches it', () async {
      final local = _FakeLocal();
      final remote = _FakeRemote(profile: testModel);
      final repo = DriverProfileRepositoryImpl(remote, local);

      final result = await repo.getProfile('uid-1');

      expect(result.uid, equals('uid-1'));
      expect(result.name, equals('Test Driver'));
      // Ensure it was cached
      final cached = await local.getProfile('uid-1');
      expect(cached, isNotNull);
      expect(cached!.uid, equals('uid-1'));
    });

    test('getProfile falls back to cache on remote error', () async {
      final local = _FakeLocal(cachedProfile: testEntity);
      final remote = _FakeRemote(shouldThrow: true);
      final repo = DriverProfileRepositoryImpl(remote, local);

      final result = await repo.getProfile('uid-1');

      expect(result.uid, equals('uid-1'));
    });

    test('getProfile rethrows when remote fails and cache is empty', () async {
      final local = _FakeLocal();
      final remote = _FakeRemote(shouldThrow: true);
      final repo = DriverProfileRepositoryImpl(remote, local);

      expect(() => repo.getProfile('uid-1'), throwsException);
    });

    test('updateProfile writes to remote and saves to cache', () async {
      final local = _FakeLocal();
      final remote = _FakeRemote(profile: testModel);
      final repo = DriverProfileRepositoryImpl(remote, local);

      await repo.updateProfile(testEntity);

      final cached = await local.getProfile('uid-1');
      expect(cached, isNotNull);
      expect(cached!.name, equals('Test Driver'));
    });

    test('getCachedProfile returns null when cache is empty', () async {
      final local = _FakeLocal();
      final remote = _FakeRemote(profile: testModel);
      final repo = DriverProfileRepositoryImpl(remote, local);

      final result = await repo.getCachedProfile('uid-1');
      expect(result, isNull);
    });

    test('getCachedProfile returns cached profile when available', () async {
      final local = _FakeLocal(cachedProfile: testEntity);
      final remote = _FakeRemote(profile: testModel);
      final repo = DriverProfileRepositoryImpl(remote, local);

      final result = await repo.getCachedProfile('uid-1');
      expect(result, isNotNull);
      expect(result!.uid, equals('uid-1'));
    });

    test('uploadAvatar returns download URL', () async {
      final local = _FakeLocal();
      final remote = _FakeRemote(profile: testModel);
      final repo = DriverProfileRepositoryImpl(remote, local);

      final url = await repo.uploadAvatar('uid-1', '/path/to/image.jpg');
      expect(url, equals('https://example.com/avatar.jpg'));
    });
  });
}
