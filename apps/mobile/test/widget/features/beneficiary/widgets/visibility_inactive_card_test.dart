import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/visibility_inactive_card.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

Widget _buildCard(VisibilityInactiveVariant variant) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: VisibilityInactiveCard(variant: variant)),
  );
}

void main() {
  group('VisibilityInactiveCard — intakePaused variant', () {
    testWidgets('shows title Intake Paused', (tester) async {
      await tester.pumpWidget(
        _buildCard(VisibilityInactiveVariant.intakePaused),
      );
      await tester.pumpAndSettle();

      expect(find.text('Intake Paused'), findsOneWidget);
    });

    testWidgets('body contains hidden from the donor map', (tester) async {
      await tester.pumpWidget(
        _buildCard(VisibilityInactiveVariant.intakePaused),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('hidden from the donor map'), findsOneWidget);
    });

    testWidgets('shows visibility_off_outlined icon', (tester) async {
      await tester.pumpWidget(
        _buildCard(VisibilityInactiveVariant.intakePaused),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });

  group('VisibilityInactiveCard — visibilityInactive variant', () {
    testWidgets('shows title Visibility Inactive', (tester) async {
      await tester.pumpWidget(
        _buildCard(VisibilityInactiveVariant.visibilityInactive),
      );
      await tester.pumpAndSettle();

      expect(find.text('Visibility Inactive'), findsOneWidget);
    });

    testWidgets('body contains Existing batches in transit will still arrive', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(VisibilityInactiveVariant.visibilityInactive),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Existing batches in transit will still arrive'),
        findsOneWidget,
      );
    });

    testWidgets('shows visibility_off_outlined icon', (tester) async {
      await tester.pumpWidget(
        _buildCard(VisibilityInactiveVariant.visibilityInactive),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
