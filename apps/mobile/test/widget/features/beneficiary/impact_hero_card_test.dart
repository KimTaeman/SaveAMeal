import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/beneficiary_impact_screen.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/impact_hero_card.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

Widget _buildCard(BeneficiaryImpact impact) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: ImpactHeroCard(impact: impact)),
);

/// Returns true when any [RichText] in the tree has a span containing [text].
bool _richTextContains(WidgetTester tester, String text) {
  return tester
      .widgetList<RichText>(find.byType(RichText))
      .any((rt) => rt.text.toPlainText().contains(text));
}

void main() {
  group('ImpactHeroCard', () {
    testWidgets('shows 0 Meals and Start your journey in zero state', (
      tester,
    ) async {
      await tester.pumpWidget(_buildCard(BeneficiaryImpact.empty));
      await tester.pumpAndSettle();

      expect(_richTextContains(tester, '0 Meals'), isTrue);
      expect(find.text('Start your journey'), findsOneWidget);
    });

    testWidgets('shows meal count and percentage caption when meals > 0', (
      tester,
    ) async {
      const impact = BeneficiaryImpact(
        totalMeals: 5000,
        totalKg: 2000.0,
        totalCo2e: 2000.0,
        totalDeliveries: 25,
        byCategory: {},
      );

      await tester.pumpWidget(_buildCard(impact));
      await tester.pumpAndSettle();

      expect(_richTextContains(tester, '5000'), isTrue);
      expect(_richTextContains(tester, 'Meals'), isTrue);
      // 5000 / 10000 * 100 = 50%
      expect(find.text('50% of yearly goal'), findsOneWidget);
    });

    testWidgets(
      'progress bar value equals totalMeals / kBeneficiaryYearlyGoalMeals',
      (tester) async {
        const impact = BeneficiaryImpact(
          totalMeals: 2500,
          totalKg: 1000.0,
          totalCo2e: 1000.0,
          totalDeliveries: 10,
          byCategory: {},
        );

        await tester.pumpWidget(_buildCard(impact));
        await tester.pumpAndSettle();

        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        final expectedValue = (2500 / kBeneficiaryYearlyGoalMeals).clamp(
          0.0,
          1.0,
        );
        expect(indicator.value, closeTo(expectedValue, 0.0001));
      },
    );

    testWidgets(
      'progress bar value is clamped to 1.0 when meals exceed yearly goal',
      (tester) async {
        const impact = BeneficiaryImpact(
          totalMeals: 15000,
          totalKg: 6000.0,
          totalCo2e: 6000.0,
          totalDeliveries: 60,
          byCategory: {},
        );

        await tester.pumpWidget(_buildCard(impact));
        await tester.pumpAndSettle();

        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, 1.0);
        // Caption uses unclamped ratio: 15000/10000*100 = 150%
        expect(find.text('150% of yearly goal'), findsOneWidget);
      },
    );

    testWidgets('shows TOTAL IMPACT label', (tester) async {
      await tester.pumpWidget(_buildCard(BeneficiaryImpact.empty));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL IMPACT'), findsOneWidget);
    });
  });
}
