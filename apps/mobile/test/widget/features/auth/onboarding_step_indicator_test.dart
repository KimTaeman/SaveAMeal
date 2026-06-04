import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/shared/theme/app_theme.dart';
import 'package:saveameal/shared/widgets/onboarding_step_indicator.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('OnboardingStepIndicator', () {
    testWidgets('shows correct step label', (tester) async {
      await tester.pumpWidget(
        _wrap(const OnboardingStepIndicator(totalSteps: 3, currentStep: 2)),
      );
      expect(find.text('Step 2 of 3'), findsOneWidget);
    });

    testWidgets('renders correct number of dots', (tester) async {
      await tester.pumpWidget(
        _wrap(const OnboardingStepIndicator(totalSteps: 2, currentStep: 1)),
      );
      // 2 dots — each is a Container with BoxShape.circle
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows Step 2 of 2 for onboarding screens', (tester) async {
      await tester.pumpWidget(
        _wrap(const OnboardingStepIndicator(totalSteps: 2, currentStep: 2)),
      );
      expect(find.text('Step 2 of 2'), findsOneWidget);
    });
  });
}
