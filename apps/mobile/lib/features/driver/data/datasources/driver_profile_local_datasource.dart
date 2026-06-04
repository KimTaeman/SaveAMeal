import 'package:hive_flutter/hive_flutter.dart';
import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';

abstract class DriverProfileLocalDatasource {
  /// Returns the cached [DriverProfile] for [uid], or null if not cached.
  Future<DriverProfile?> getProfile(String uid);

  /// Writes [profile] to the Hive cache under key [uid].
  Future<void> saveProfile(DriverProfile profile);
}

class DriverProfileLocalDatasourceImpl implements DriverProfileLocalDatasource {
  DriverProfileLocalDatasourceImpl()
    : _box = Hive.box<dynamic>('driver_profile');
  final Box<dynamic> _box;

  @override
  Future<DriverProfile?> getProfile(String uid) async {
    final raw = _box.get(uid);
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(raw as Map);
    return DriverProfile(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      photoUrl: map['photoUrl'] as String?,
      vehicleType: map['vehicleType'] as String?,
      licensePlate: map['licensePlate'] as String?,
      emergencyContact: map['emergencyContact'] as String?,
    );
  }

  @override
  Future<void> saveProfile(DriverProfile profile) async {
    await _box.put(profile.uid, {
      'uid': profile.uid,
      'name': profile.name,
      'email': profile.email,
      'phone': profile.phone,
      'photoUrl': profile.photoUrl,
      'vehicleType': profile.vehicleType,
      'licensePlate': profile.licensePlate,
      'emergencyContact': profile.emergencyContact,
    });
  }
}
