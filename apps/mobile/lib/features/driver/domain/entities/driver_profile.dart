// ignore_for_file: public_member_api_docs
class DriverProfile {
  const DriverProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.vehicleType,
    this.licensePlate,
    this.emergencyContact,
    this.joinDate,
    this.totalPickups,
    this.vehicleColor,
    this.cargoCapacity,
    this.refrigeratedStorage,
    this.insurancePolicyNumber,
    this.primaryLocation,
  });

  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String? vehicleType;
  final String? licensePlate;
  final String? emergencyContact;

  /// Human-readable join date, e.g. "Oct 2024".
  final String? joinDate;

  /// Cumulative number of completed pickups.
  final int? totalPickups;

  /// Vehicle colour, e.g. "Silver".
  final String? vehicleColor;

  /// One of: 'Small' | 'Medium' | 'Large' | 'Extra Large'.
  final String? cargoCapacity;

  /// Whether the vehicle has refrigerated storage.
  final bool? refrigeratedStorage;

  /// Insurance policy number.
  final String? insurancePolicyNumber;

  /// Driver's primary service location (city, neighbourhood, or zip).
  final String? primaryLocation;

  DriverProfile copyWith({
    String? uid,
    String? name,
    String? email,
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
  }) {
    return DriverProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      licensePlate: licensePlate ?? this.licensePlate,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      joinDate: joinDate ?? this.joinDate,
      totalPickups: totalPickups ?? this.totalPickups,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      cargoCapacity: cargoCapacity ?? this.cargoCapacity,
      refrigeratedStorage: refrigeratedStorage ?? this.refrigeratedStorage,
      insurancePolicyNumber:
          insurancePolicyNumber ?? this.insurancePolicyNumber,
      primaryLocation: primaryLocation ?? this.primaryLocation,
    );
  }
}
