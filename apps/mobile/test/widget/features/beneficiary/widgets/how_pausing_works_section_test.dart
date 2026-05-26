import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/how_pausing_works_section.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

Widget buildSection() {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: SingleChildScrollView(child: const HowPausingWorksSection()),
    ),
  );
}

void main() {
  group('HowPausingWorksSection', () {
    testWidgets('renders HOW STATUS PAUSING WORKS heading', (tester) async {
      await tester.pumpWidget(buildSection());
      await tester.pumpAndSettle();

      expect(find.text('HOW STATUS PAUSING WORKS'), findsOneWidget);
    });

    testWidgets('step 1 text contains removes your pin from the donor map', (
      tester,
    ) async {
      await tester.pumpWidget(buildSection());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('removes your pin from the donor map'),
        findsOneWidget,
      );
    });

    testWidgets('step 2 text contains Active deliveries will not be canceled', (
      tester,
    ) async {
      await tester.pumpWidget(buildSection());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Active deliveries will not be canceled'),
        findsOneWidget,
      );
    });

    testWidgets('step 3 text contains Toggle back to Accepting', (
      tester,
    ) async {
      await tester.pumpWidget(buildSection());
      await tester.pumpAndSettle();

      expect(find.textContaining('Toggle back to Accepting'), findsOneWidget);
    });

    testWidgets('renders three CircleAvatars with labels 1, 2, 3', (
      tester,
    ) async {
      await tester.pumpWidget(buildSection());
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsNWidgets(3));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });
}
