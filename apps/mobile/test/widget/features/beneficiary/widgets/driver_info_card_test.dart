import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/core/models/driver_location_model.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/driver_info_card.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

IntakeRequestDetail _makeDetail({
  String? volunteerId,
  String? volunteerName,
  int? estimatedArrivalMinutes,
}) => IntakeRequestDetail(
  batchId: 'b_001',
  beneficiaryId: 'ben_001',
  donorId: 'donor_001',
  donorName: 'Test Donor',
  status: IntakeStatus.dispatched,
  portions: 1,
  weightKg: 1.0,
  items: const [],
  volunteerId: volunteerId,
  volunteerName: volunteerName,
  estimatedArrivalMinutes: estimatedArrivalMinutes,
);

Widget _buildCard(IntakeRequestDetail detail) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: DriverInfoCard(detail: detail)),
  ),
);

Widget _buildCardWithLocationOverride(
  IntakeRequestDetail detail,
  String driverId,
  Stream<DriverLocationModel?> locationStream,
) => ProviderScope(
  overrides: [
    driverLocationProvider(driverId).overrideWith((_) => locationStream),
  ],
  child: MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: DriverInfoCard(detail: detail)),
  ),
);

void main() {
  group('DriverInfoCard', () {
    testWidgets(
      'state (a): no driver assigned — shows placeholder icon, hides chips',
      (tester) async {
        final detail = _makeDetail(volunteerId: null);
        await tester.pumpWidget(_buildCard(detail));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
        expect(find.text('Locating driver…'), findsNothing);
        expect(find.text('En route'), findsNothing);
        expect(find.text('ETA unknown'), findsOneWidget);
      },
    );

    testWidgets(
      'state (b): driver assigned, no GPS — shows "Locating driver…" chip',
      (tester) async {
        const driverId = 'driver_001';
        final detail = _makeDetail(
          volunteerId: driverId,
          volunteerName: 'Nattapong',
          estimatedArrivalMinutes: 15,
        );
        await tester.pumpWidget(
          _buildCardWithLocationOverride(detail, driverId, Stream.value(null)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Locating driver…'), findsOneWidget);
        expect(find.text('En route'), findsNothing);
        expect(find.byIcon(Icons.local_shipping_outlined), findsNothing);
        expect(find.text('Nattapong'), findsOneWidget);
        expect(find.text('15 min'), findsOneWidget);
      },
    );

    testWidgets('state (c): driver assigned with GPS — shows "En route" chip', (
      tester,
    ) async {
      const driverId = 'driver_001';
      final detail = _makeDetail(
        volunteerId: driverId,
        volunteerName: 'Nattapong',
        estimatedArrivalMinutes: 8,
      );
      final loc = DriverLocationModel(
        driverId: driverId,
        lat: 13.76,
        lng: 100.50,
      );
      await tester.pumpWidget(
        _buildCardWithLocationOverride(detail, driverId, Stream.value(loc)),
      );
      await tester.pumpAndSettle();

      expect(find.text('En route'), findsOneWidget);
      expect(find.text('Locating driver…'), findsNothing);
      expect(find.byIcon(Icons.local_shipping_outlined), findsNothing);
      expect(find.text('8 min'), findsOneWidget);
    });

    testWidgets(
      'ETA is clamped to 600 minutes maximum for out-of-range values',
      (tester) async {
        const driverId = 'driver_001';
        final detail = _makeDetail(
          volunteerId: driverId,
          estimatedArrivalMinutes: 999,
        );
        await tester.pumpWidget(
          _buildCardWithLocationOverride(detail, driverId, Stream.value(null)),
        );
        await tester.pumpAndSettle();

        expect(find.text('600 min'), findsOneWidget);
        expect(find.text('999 min'), findsNothing);
      },
    );

    testWidgets('shows "ETA unknown" when estimatedArrivalMinutes is null', (
      tester,
    ) async {
      final detail = _makeDetail(
        volunteerId: null,
        estimatedArrivalMinutes: null,
      );
      await tester.pumpWidget(_buildCard(detail));
      await tester.pumpAndSettle();

      expect(find.text('ETA unknown'), findsOneWidget);
    });
  });
}
