// Pure Dart entity — zero Flutter or backend imports.

class BeneficiaryProfile {
  const BeneficiaryProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.mealsReceived,
    this.phone,
    this.location,
    this.photoUrl,
    this.orgName,
    this.address,
    this.orgType,
    this.contactEmail,
    this.missionStatement,
    this.latitude,
    this.longitude,
    this.joinedAt,
  });

  final String uid;
  final String name; // from users/{uid}.name
  final String email; // from users/{uid}.email
  final String role; // from users/{uid}.role
  final int
  mealsReceived; // computed aggregate: sum of (entry.totalWeightKg * 2.5).round()
  final String? phone; // from users/{uid}.phone
  final String? location; // from users/{uid}.location (free-text)
  final String? photoUrl; // from users/{uid}.photoUrl
  final String? orgName; // from beneficiaries/{uid}.name
  final String? address; // from beneficiaries/{uid}.address
  final String? orgType; // from beneficiaries/{uid}.orgType  — NEW
  final String? contactEmail; // from beneficiaries/{uid}.contactEmail — NEW
  final String?
  missionStatement; // from beneficiaries/{uid}.missionStatement — NEW
  final double? latitude; // from beneficiaries/{uid}.lat
  final double? longitude; // from beneficiaries/{uid}.lng
  final DateTime? joinedAt; // derived in datasource from FirebaseAuth metadata
}
