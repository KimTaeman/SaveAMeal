// Pure Dart entity — zero Flutter or backend imports.

class BeneficiaryOrgProfileUpdate {
  const BeneficiaryOrgProfileUpdate({
    this.orgName,
    this.address,
    this.orgType,
    this.contactEmail,
    this.missionStatement,
  });

  final String? orgName;
  final String? address;
  final String? orgType;
  final String? contactEmail;
  final String? missionStatement;
}
