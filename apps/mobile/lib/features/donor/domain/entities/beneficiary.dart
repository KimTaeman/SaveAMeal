// Pure Dart entity — zero Flutter or backend imports.
class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.name,
    this.address,
    this.orgType,
    this.contactEmail,
    this.missionStatement,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String? address;
  final String? orgType;
  final String? contactEmail;
  final String? missionStatement;
  final double? latitude;
  final double? longitude;
}
