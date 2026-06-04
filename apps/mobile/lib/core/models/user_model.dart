import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

enum UserRole { donor, driver, beneficiary }

enum BeneficiaryStatus { accepting, full }

@freezed
sealed class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String name,
    required String email,
    required UserRole role,
    String? phone,
    String? orgName,
    String? location,
    String? photoUrl,
    String? managerName,
    String? streetAddress,
    String? bannerUrl,
    BeneficiaryStatus? status,
    @Default(0) int points,
    @Default([]) List<Map<String, String>> operatingHours,
    @Default([]) List<String> surplusTypes,
    String? fcmToken,
    double? latitude,
    double? longitude,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
