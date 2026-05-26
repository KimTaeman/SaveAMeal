import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/volunteer/presentation/screens/volunteer_delivery_scanner_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

void main() {
  group('VolunteerDeliveryScannerScreen', () {
    testWidgets('shows AppBar title Scan QR to Confirm Delivery', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const VolunteerDeliveryScannerScreen(batchId: 'scan-batch-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scan QR to Confirm Delivery'), findsOneWidget);
    });

    testWidgets('shows the batchId in the body', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const VolunteerDeliveryScannerScreen(batchId: 'scan-batch-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('batchId: scan-batch-1'), findsOneWidget);
    });
  });
}
