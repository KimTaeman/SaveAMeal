import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';

part 'driver_profile_model.freezed.dart';
part 'driver_profile_model.g.dart';

@freezed
sealed class DriverProfileModel with _$DriverProfileModel {
  const factory DriverProfileModel({
    required String uid,
    required String name,
    required String email,
    String? phone,
    String? photoUrl,
    String? vehicleType,
    String? licensePlate,
    String? emergencyContact,
    String? joinDate,
    int? totalPickups,
    String? vehicleColor,
    String? cargoCapacity,
    bool? refrigeratedStorage,
    String? insurancePolicyNumber,
    String? primaryLocation,
  }) = _DriverProfileModel;

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) =>
      _$DriverProfileModelFromJson(json);
}

extension DriverProfileModelX on DriverProfileModel {
  DriverProfile toEntity() => DriverProfile(
    uid: uid,
    name: name,
    email: email,
    phone: phone,
    photoUrl: photoUrl,
    vehicleType: vehicleType,
    licensePlate: licensePlate,
    emergencyContact: emergencyContact,
    joinDate: joinDate,
    totalPickups: totalPickups,
    vehicleColor: vehicleColor,
    cargoCapacity: cargoCapacity,
    refrigeratedStorage: refrigeratedStorage,
    insurancePolicyNumber: insurancePolicyNumber,
    primaryLocation: primaryLocation,
  );
}

extension DriverProfileX on DriverProfile {
  DriverProfileModel toModel() => DriverProfileModel(
    uid: uid,
    name: name,
    email: email,
    phone: phone,
    photoUrl: photoUrl,
    vehicleType: vehicleType,
    licensePlate: licensePlate,
    emergencyContact: emergencyContact,
    joinDate: joinDate,
    totalPickups: totalPickups,
    vehicleColor: vehicleColor,
    cargoCapacity: cargoCapacity,
    refrigeratedStorage: refrigeratedStorage,
    insurancePolicyNumber: insurancePolicyNumber,
    primaryLocation: primaryLocation,
  );
}
