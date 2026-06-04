import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:saveameal/core/models/beneficiary_model.dart';
import 'package:saveameal/core/models/user_model.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_profile.dart';

part 'beneficiary_profile_model.freezed.dart';
part 'beneficiary_profile_model.g.dart';

/// Merges data from the Firestore `users` and `beneficiaries` documents.
/// Constructed directly by the datasource from two already-deserialized models.
@freezed
abstract class BeneficiaryProfileModel with _$BeneficiaryProfileModel {
  const BeneficiaryProfileModel._();

  const factory BeneficiaryProfileModel({
    required UserModel userModel,
    BeneficiaryModel? beneficiaryModel,
    required int mealsReceived,
    DateTime? joinedAt,
  }) = _BeneficiaryProfileModel;

  factory BeneficiaryProfileModel.fromJson(Map<String, dynamic> json) =>
      _$BeneficiaryProfileModelFromJson(json);

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
