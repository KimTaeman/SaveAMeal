import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:saveameal/features/driver/data/models/driver_profile_model.dart';

abstract class DriverProfileRemoteDatasource {
  /// Reads `users/{uid}` from Firestore and returns a [DriverProfileModel].
  Future<DriverProfileModel> getProfile(String uid);

  /// Writes editable fields to `users/{uid}` using SetOptions(merge: true).
  /// Always writes `updatedAt` as a server timestamp.
  Future<void> updateProfile(DriverProfileModel model);

  /// Uploads a local file to `avatars/drivers/{uid}.jpg` in Firebase Storage
  /// and returns the public download URL.
  Future<String> uploadAvatar(String uid, Uint8List bytes);
}

class DriverProfileRemoteDatasourceImpl
    implements DriverProfileRemoteDatasource {
  const DriverProfileRemoteDatasourceImpl(this._firestore, this._storage);
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Future<DriverProfileModel> getProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) throw Exception('Driver profile not found for $uid');
    final json = <String, dynamic>{...data, 'uid': uid};
    if (json['joinDate'] == null && data['createdAt'] is Timestamp) {
      final dt = (data['createdAt'] as Timestamp).toDate();
      json['joinDate'] =
          '${dt.day.toString().padLeft(2, '0')} ${_months[dt.month - 1]} ${dt.year}';
    }
    return DriverProfileModel.fromJson(json);
  }

  @override
  Future<void> updateProfile(DriverProfileModel model) async {
    await _firestore.collection('users').doc(model.uid).set({
      'name': model.name,
      'phone': model.phone,
      'photoUrl': model.photoUrl,
      'vehicleType': model.vehicleType,
      'licensePlate': model.licensePlate,
      'emergencyContact': model.emergencyContact,
      'joinDate': model.joinDate,
      'totalPickups': model.totalPickups,
      'vehicleColor': model.vehicleColor,
      'cargoCapacity': model.cargoCapacity,
      'refrigeratedStorage': model.refrigeratedStorage,
      'insurancePolicyNumber': model.insurancePolicyNumber,
      'primaryLocation': model.primaryLocation,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<String> uploadAvatar(String uid, Uint8List bytes) async {
    final ref = _storage.ref('avatars/drivers/$uid.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
