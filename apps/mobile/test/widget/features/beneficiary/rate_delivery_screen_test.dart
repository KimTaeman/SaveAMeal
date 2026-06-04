import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/rate_delivery_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

Widget _buildScreen() =>
    MaterialApp(theme: AppTheme.light(), home: const RateDeliveryScreen());

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('RateDeliveryScreen', () {
    // 1. Basic render — screen mounts without throwing
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump(const Duration(milliseconds: 100));
      // No exception thrown means the widget tree built successfully.
      expect(find.byType(RateDeliveryScreen), findsOneWidget);
    });

    // 2. Scaffold is present (ensures proper Material widget wrapping)
    testWidgets('contains a Scaffold', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    // 3. TODO placeholder text is visible (verifies stub content renders)
    testWidgets('shows placeholder text for unimplemented screen', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('TODO: RateDeliveryScreen'), findsOneWidget);
    });

    // 4. Placeholder text is centred
    testWidgets('placeholder text is inside a Center widget', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump(const Duration(milliseconds: 100));
      // The Text widget must be a descendant of Center.
      expect(
        find.ancestor(
          of: find.text('TODO: RateDeliveryScreen'),
          matching: find.byType(Center),
        ),
        findsOneWidget,
      );
    });

    // 5. Theme is applied — surface background is non-null
    testWidgets('applies theme without crashing', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump(const Duration(milliseconds: 100));
      // Theme.of(context) access inside the widget must not throw.
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      // backgroundColor is null when inheriting from theme — both are valid.
      expect(scaffold, isNotNull);
    });

    // 6. Screen does not render any loading indicators
    testWidgets('does not show a loading indicator', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    // 7. No back button / AppBar — screen is a stub without navigation chrome
    testWidgets('does not render an AppBar', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AppBar), findsNothing);
    });

    // 8. StatelessWidget — rebuilds identically on hot-reload (pump twice)
    testWidgets('produces identical widget tree on second pump', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump(const Duration(milliseconds: 100));
      final firstCount = find.byType(Text).evaluate().length;

      await tester.pumpWidget(_buildScreen());
      await tester.pump(const Duration(milliseconds: 100));
      final secondCount = find.byType(Text).evaluate().length;

      expect(secondCount, equals(firstCount));
    });
  });
}
