import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/active_delivery_card.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Helper factory ─────────────────────────────────────────────────────────────

IntakeRequest _makeRequest({
  IntakeStatus status = IntakeStatus.dispatched,
  String? volunteerName,
  int? estimatedArrivalMinutes,
}) => IntakeRequest(
  batchId: 'batch-001',
  beneficiaryId: 'ben-001',
  donorId: 'donor-001',
  status: status,
  portions: 10,
  mealDescription: 'Rice and curry',
  weightKg: 5.0,
  volunteerName: volunteerName,
  estimatedArrivalMinutes: estimatedArrivalMinutes,
);

Widget _buildCard({
  required IntakeRequest request,
  VoidCallback? onViewDetails,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: ActiveDeliveryCard(
        request: request,
        onViewDetails: onViewDetails ?? () {},
      ),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('ActiveDeliveryCard', () {
    testWidgets('shows IN TRANSIT badge when status is dispatched', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(request: _makeRequest(status: IntakeStatus.dispatched)),
      );
      await tester.pumpAndSettle();

      expect(find.text('IN TRANSIT'), findsOneWidget);
    });

    testWidgets('shows AWAITING VOLUNTEER badge when status is pending', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(request: _makeRequest(status: IntakeStatus.pending)),
      );
      await tester.pumpAndSettle();

      expect(find.text('AWAITING VOLUNTEER'), findsOneWidget);
    });

    testWidgets('shows ETA text when estimatedArrivalMinutes is not null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(request: _makeRequest(estimatedArrivalMinutes: 15)),
      );
      await tester.pumpAndSettle();

      expect(find.text('ETA 15 min'), findsOneWidget);
    });

    testWidgets('does not show ETA text when estimatedArrivalMinutes is null', (
      tester,
    ) async {
      await tester.pumpWidget(_buildCard(request: _makeRequest()));
      await tester.pumpAndSettle();

      expect(find.textContaining('ETA'), findsNothing);
    });

    testWidgets('shows volunteer name when volunteerName is not null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(request: _makeRequest(volunteerName: 'Alex')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Alex'), findsOneWidget);
    });

    testWidgets('shows A volunteer when volunteerName is null', (tester) async {
      await tester.pumpWidget(_buildCard(request: _makeRequest()));
      await tester.pumpAndSettle();

      expect(find.textContaining('A volunteer'), findsOneWidget);
    });

    testWidgets('shows portions and mealDescription', (tester) async {
      await tester.pumpWidget(_buildCard(request: _makeRequest()));
      await tester.pumpAndSettle();

      expect(find.text('10 portions • Rice and curry'), findsOneWidget);
    });

    testWidgets('tapping View Details calls onViewDetails', (tester) async {
      var called = false;

      await tester.pumpWidget(
        _buildCard(request: _makeRequest(), onViewDetails: () => called = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Details →'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });
}
