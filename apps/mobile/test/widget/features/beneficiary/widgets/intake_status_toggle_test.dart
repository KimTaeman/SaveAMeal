import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/intake_status_toggle.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

Widget buildToggle({
  required BeneficiaryIntakeAvailability availability,
  required ValueChanged<BeneficiaryIntakeAvailability> onChanged,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: IntakeStatusToggle(
        availability: availability,
        onChanged: onChanged,
      ),
    ),
  );
}

void main() {
  group('IntakeStatusToggle', () {
    testWidgets('renders Accepting and Full / Busy labels', (tester) async {
      await tester.pumpWidget(
        buildToggle(
          availability: BeneficiaryIntakeAvailability.accepting,
          onChanged: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accepting'), findsOneWidget);
      expect(find.text('Full / Busy'), findsOneWidget);
    });

    testWidgets(
      'onChanged called with fullBusy when Full / Busy tapped from accepting',
      (tester) async {
        BeneficiaryIntakeAvailability? changed;

        await tester.pumpWidget(
          buildToggle(
            availability: BeneficiaryIntakeAvailability.accepting,
            onChanged: (v) => changed = v,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Full / Busy'));
        await tester.pumpAndSettle();

        expect(changed, BeneficiaryIntakeAvailability.fullBusy);
      },
    );

    testWidgets(
      'onChanged called with accepting when Accepting tapped from fullBusy',
      (tester) async {
        BeneficiaryIntakeAvailability? changed;

        await tester.pumpWidget(
          buildToggle(
            availability: BeneficiaryIntakeAvailability.fullBusy,
            onChanged: (v) => changed = v,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Accepting'));
        await tester.pumpAndSettle();

        expect(changed, BeneficiaryIntakeAvailability.accepting);
      },
    );
  });
}
