import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/volunteer/presentation/screens/volunteer_queue_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

void main() {
  group('VolunteerQueueScreen', () {
    testWidgets('shows Volunteer Queue — TODO text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const VolunteerQueueScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Volunteer Queue — TODO'), findsOneWidget);
    });
  });
}
