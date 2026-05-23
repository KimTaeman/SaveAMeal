import 'package:saveameal/features/donor/domain/entities/food_category.dart';

class BatchItem {
  const BatchItem({
    required this.name,
    required this.category,
    required this.weightKg,
    required this.expiryTime,
    this.photoUrl,
    this.localPhotoPath,
  });

  final String name;
  final FoodCategory category;
  final double weightKg;
  final DateTime expiryTime;
  final String? photoUrl;
  final String? localPhotoPath;
}
