import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/delivery_detail_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

void main() {
  group('DeliveryDetailScreen', () {
    testWidgets('shows AppBar title Delivery Details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const DeliveryDetailScreen(batchId: 'test-batch'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delivery Details'), findsOneWidget);
    });

    testWidgets('shows the batchId passed as constructor argument', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const DeliveryDetailScreen(batchId: 'test-batch'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('batchId: test-batch'), findsOneWidget);
    });
  });
}
