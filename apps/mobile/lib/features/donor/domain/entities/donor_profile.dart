// Pure Dart entity — zero Flutter or backend imports.
class DonorProfile {
  const DonorProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.location,
    this.photoUrl,
    this.orgName,
    this.managerName,
    this.streetAddress,
    this.bannerUrl,
    this.operatingHours = const [],
    this.surplusTypes = const [],
    this.latitude,
    this.longitude,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? location;
  final String? photoUrl;
  final String? orgName;
  final String? managerName;
  final String? streetAddress;
  final String? bannerUrl;
  final List<Map<String, String>> operatingHours;
  final List<String> surplusTypes;
  final double? latitude;
  final double? longitude;
}
