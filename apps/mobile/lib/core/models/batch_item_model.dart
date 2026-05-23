import 'package:freezed_annotation/freezed_annotation.dart';

part 'batch_item_model.freezed.dart';
part 'batch_item_model.g.dart';

@freezed
sealed class BatchItemModel with _$BatchItemModel {
  const factory BatchItemModel({
    required String name,
    required String category,
    required double weightKg,
    required DateTime expiryTime,
    String? photoUrl,
  }) = _BatchItemModel;

  factory BatchItemModel.fromJson(Map<String, dynamic> json) =>
      _$BatchItemModelFromJson(json);
}
