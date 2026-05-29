import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/volunteer/presentation/widgets/pending_request_card.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

void main() {
  group('PendingRequestCard', () {
    testWidgets('renders without error and finds Placeholder widget', (
      tester,
    ) async {
      const request = IntakeRequest(
        batchId: 'batch-pen-001',
        beneficiaryId: 'ben-001',
        donorId: 'donor-001',
        status: IntakeStatus.pending,
        portions: 4,
        mealDescription: 'Fried rice',
        weightKg: 2.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: PendingRequestCard(
              request: request,
              onAccept: null,
              onScanQr: null,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Placeholder), findsOneWidget);
    });
  });
}
