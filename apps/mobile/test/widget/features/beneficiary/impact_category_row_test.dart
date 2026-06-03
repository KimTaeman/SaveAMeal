import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/impact_category_row.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

Widget _buildRow({
  required FoodCategory category,
  required double kg,
  required double totalKg,
}) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(
    body: ImpactCategoryRow(category: category, kg: kg, totalKg: totalKg),
  ),
);

void main() {
  group('ImpactCategoryRow', () {
    testWidgets('renders correct display name for bakery', (tester) async {
      await tester.pumpWidget(
        _buildRow(category: FoodCategory.bakery, kg: 100.0, totalKg: 400.0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bakery'), findsOneWidget);
    });

    testWidgets('renders correct display name for produce', (tester) async {
      await tester.pumpWidget(
        _buildRow(category: FoodCategory.produce, kg: 200.0, totalKg: 400.0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Produce'), findsOneWidget);
    });

    testWidgets('renders correct display name for dairy', (tester) async {
      await tester.pumpWidget(
        _buildRow(category: FoodCategory.dairy, kg: 50.0, totalKg: 400.0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dairy'), findsOneWidget);
    });

    testWidgets('renders correct display name for meat', (tester) async {
      await tester.pumpWidget(
        _buildRow(category: FoodCategory.meat, kg: 30.0, totalKg: 400.0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Meat'), findsOneWidget);
    });

    testWidgets('renders correct display name for beverages', (tester) async {
      await tester.pumpWidget(
        _buildRow(category: FoodCategory.beverages, kg: 10.0, totalKg: 400.0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Beverages'), findsOneWidget);
    });

    testWidgets('renders correct display name for other', (tester) async {
      await tester.pumpWidget(
        _buildRow(category: FoodCategory.other, kg: 10.0, totalKg: 400.0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('shows correct percentage text', (tester) async {
      // 200 / 400 * 100 = 50%
      await tester.pumpWidget(
        _buildRow(category: FoodCategory.produce, kg: 200.0, totalKg: 400.0),
      );
      await tester.pumpAndSettle();
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('rounds percentage correctly', (tester) async {
      // 1 / 3 * 100 = 33.33... → rounds to 33%
      await tester.pumpWidget(
        _buildRow(category: FoodCategory.bakery, kg: 1.0, totalKg: 3.0),
      );
      await tester.pumpAndSettle();
      expect(find.text('33%'), findsOneWidget);
    });

    testWidgets('renders correct icon for bakery category', (tester) async {
      await tester.pumpWidget(
        _buildRow(category: FoodCategory.bakery, kg: 50.0, totalKg: 100.0),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bakery_dining_outlined), findsOneWidget);
    });

    testWidgets('renders correct icon for produce category', (tester) async {
      await tester.pumpWidget(
        _buildRow(category: FoodCategory.produce, kg: 50.0, totalKg: 100.0),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.eco_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('renders correct icon for other category', (tester) async {
      await tester.pumpWidget(
        _buildRow(category: FoodCategory.other, kg: 50.0, totalKg: 100.0),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
    });
  });
}
