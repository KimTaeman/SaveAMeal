import 'package:freezed_annotation/freezed_annotation.dart';

part 'beneficiary_model.freezed.dart';
part 'beneficiary_model.g.dart';

@freezed
sealed class BeneficiaryModel with _$BeneficiaryModel {
  const factory BeneficiaryModel({
    required String id,
    required String name,
    String? address,
    double? lat,
    double? lng,
  }) = _BeneficiaryModel;

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) =>
      _$BeneficiaryModelFromJson(json);
}
