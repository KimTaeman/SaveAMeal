import 'package:flutter/material.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';

class ImpactCategoryRow extends StatelessWidget {
  const ImpactCategoryRow({
    required this.category,
    required this.kg,
    required this.totalKg,
    super.key,
  });

  final FoodCategory category;
  final double kg;
  final double totalKg;

  String _categoryDisplayName(FoodCategory cat) {
    switch (cat) {
      case FoodCategory.bakery:
        return 'Bakery';
      case FoodCategory.produce:
        return 'Produce';
      case FoodCategory.dairy:
        return 'Dairy';
      case FoodCategory.meat:
        return 'Meat';
      case FoodCategory.beverages:
        return 'Beverages';
      case FoodCategory.other:
        return 'Other';
    }
  }

  IconData _categoryIcon(FoodCategory cat) {
    switch (cat) {
      case FoodCategory.bakery:
        return Icons.bakery_dining_outlined;
      case FoodCategory.produce:
        return Icons.eco_outlined;
      case FoodCategory.dairy:
        return Icons.water_drop_outlined;
      case FoodCategory.meat:
        return Icons.set_meal_outlined;
      case FoodCategory.beverages:
        return Icons.local_drink_outlined;
      case FoodCategory.other:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: Icon(_categoryIcon(category), color: cs.primary),
      title: Text(_categoryDisplayName(category), style: textTheme.bodyMedium),
      trailing: Text(
        '${(kg / totalKg * 100).round()}%',
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: cs.primary,
        ),
      ),
    );
  }
}
