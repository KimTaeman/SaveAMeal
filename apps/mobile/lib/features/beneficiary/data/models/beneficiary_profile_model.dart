import 'package:saveameal/core/models/beneficiary_model.dart';
import 'package:saveameal/core/models/user_model.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_profile.dart';

/// A thin holder that merges data from two Firestore documents.
/// Not a Freezed model — no JSON serialization needed; it is constructed
/// directly by the datasource from two already-deserialized models.
class BeneficiaryProfileModel {
  const BeneficiaryProfileModel({
    required this.userModel,
    required this.beneficiaryModel,
    required this.mealsReceived,
    this.joinedAt,
  });

  final UserModel userModel;
  final BeneficiaryModel? beneficiaryModel;
  final int mealsReceived;
  final DateTime? joinedAt;

  BeneficiaryProfile toDomain() => BeneficiaryProfile(
    uid: userModel.uid,
    name: userModel.name,
    email: userModel.email,
    role: userModel.role.name,
    mealsReceived: mealsReceived,
    phone: userModel.phone,
    location: userModel.location,
    photoUrl: userModel.photoUrl,
    orgName: beneficiaryModel?.name,
    address: beneficiaryModel?.address,
    orgType: beneficiaryModel?.orgType,
    contactEmail: beneficiaryModel?.contactEmail,
    missionStatement: beneficiaryModel?.missionStatement,
    joinedAt: joinedAt,
  );
}
