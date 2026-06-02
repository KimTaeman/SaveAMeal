// Pure Dart entity — zero Flutter or backend imports.
class UserProfileUpdate {
  const UserProfileUpdate({
    this.name,
    this.phone,
    this.location,
    this.photoUrl,
    this.orgName,
    this.managerName,
    this.streetAddress,
    this.bannerUrl,
    this.operatingHours,
    this.surplusTypes,
  });

  final String? name;
  final String? phone;
  final String? location;
  final String? photoUrl;
  final String? orgName;
  final String? managerName;
  final String? streetAddress;
  final String? bannerUrl;
  final List<Map<String, String>>? operatingHours;
  final List<String>? surplusTypes;

  Map<String, dynamic> toMap() => {
    if (name != null) 'name': name,
    if (phone != null) 'phone': phone,
    if (location != null) 'location': location,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (orgName != null) 'orgName': orgName,
    if (managerName != null) 'managerName': managerName,
    if (streetAddress != null) 'streetAddress': streetAddress,
    if (bannerUrl != null) 'bannerUrl': bannerUrl,
    if (operatingHours != null) 'operatingHours': operatingHours,
    if (surplusTypes != null) 'surplusTypes': surplusTypes,
  };
}
