import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saveameal/core/models/beneficiary_model.dart';
import 'package:saveameal/core/models/driver_location_model.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/tracking_screen.dart';
import 'package:saveameal/services/firestore_service.dart';
import 'package:saveameal/services/service_providers.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────────

/// Minimal FirestoreService fake used by [TrackingScreen._loadShelterCoordinates].
/// Returns null so the screen falls back to the Bangkok default camera target.
class _FakeFirestoreService implements FirestoreService {
  final BeneficiaryModel? shelterResult;

  _FakeFirestoreService({this.shelterResult});

  @override
  Future<BeneficiaryModel?> getBeneficiary(String beneficiaryId) async =>
      shelterResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ── Fixtures ───────────────────────────────────────────────────────────────────

final _driverWithLocation = DriverLocationModel(
  driverId: 'driver_001',
  lat: 13.7563,
  lng: 100.5018,
);

// ── Helpers ────────────────────────────────────────────────────────────────────

/// Wraps [TrackingScreen] with all providers overridden to avoid real Firebase
/// calls. [locationStream] controls the driver position emitted by
/// [driverLocationProvider]. Pass a [shelterResult] to simulate a shelter with
/// known coordinates.
Widget _buildScreen({
  Stream<DriverLocationModel?>? locationStream,
  BeneficiaryModel? shelterResult,
}) {
  final stream = locationStream ?? Stream.value(null);
  return ProviderScope(
    overrides: [
      driverLocationProvider('driver_001').overrideWith((_) => stream),
      firestoreServiceProvider.overrideWithValue(
        _FakeFirestoreService(shelterResult: shelterResult),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const TrackingScreen(
        driverId: 'driver_001',
        beneficiaryId: 'ben_001',
      ),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('TrackingScreen', () {
    // 1. Basic render — screen mounts without throwing
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(TrackingScreen), findsOneWidget);
    });

    // 2. Scaffold and AppBar are present
    testWidgets('contains a Scaffold and AppBar', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    // 3. AppBar title is 'Tracking Delivery'
    testWidgets('shows Tracking Delivery in AppBar', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Tracking Delivery'), findsOneWidget);
    });

    // 4. GoogleMap widget is rendered
    testWidgets('renders a GoogleMap widget', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    // 5. Status bar shows 'Waiting for driver location…' when data is null
    testWidgets(
      'shows waiting status text when driver location data is null',
      (tester) async {
        await tester.pumpWidget(
          _buildScreen(locationStream: Stream.value(null)),
        );
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.text('Waiting for driver location…'), findsOneWidget);
      },
    );

    // 6. Status bar shows 'Driver is on the way' when location is available
    testWidgets(
      'shows on-the-way status text when driver location emits a position',
      (tester) async {
        await tester.pumpWidget(
          _buildScreen(locationStream: Stream.value(_driverWithLocation)),
        );
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.text('Driver is on the way'), findsOneWidget);
      },
    );

    // 7. Status bar shows 'Loading…' while the stream has not yet emitted
    testWidgets(
      'shows loading status text while location stream is pending',
      (tester) async {
        final controller = StreamController<DriverLocationModel?>();
        addTearDown(controller.close);

        await tester.pumpWidget(
          _buildScreen(locationStream: controller.stream),
        );
        // Only pump one frame — do not settle — so the AsyncValue stays loading.
        await tester.pump();
        expect(find.text('Loading…'), findsOneWidget);
      },
    );

    // 8. Status bar shows error text when stream emits an error
    testWidgets(
      'shows error status text when driver location stream emits an error',
      (tester) async {
        await tester.pumpWidget(
          _buildScreen(
            locationStream: Stream.error(Exception('network failure')),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.text('Unable to load driver location'), findsOneWidget);
      },
    );

    // 9. No CircularProgressIndicator is shown after data arrives
    testWidgets(
      'does not show a CircularProgressIndicator once data is loaded',
      (tester) async {
        await tester.pumpWidget(
          _buildScreen(locationStream: Stream.value(null)),
        );
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    // 10. Shelter coordinates load: when getBeneficiary returns a BeneficiaryModel
    //     with lat/lng the screen must not throw.
    testWidgets(
      'renders without error when shelter coordinates are available',
      (tester) async {
        await tester.pumpWidget(
          _buildScreen(
            locationStream: Stream.value(null),
            shelterResult: const BeneficiaryModel(
              id: 'ben_001',
              name: 'Hope Shelter',
              lat: 13.7600,
              lng: 100.5050,
            ),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.byType(TrackingScreen), findsOneWidget);
        expect(find.text('Waiting for driver location…'), findsOneWidget);
      },
    );

    // 11. Status text widget is inside the layout Column (not floating)
    testWidgets('status text is a descendant of Column', (tester) async {
      await tester.pumpWidget(
        _buildScreen(locationStream: Stream.value(null)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(
        find.ancestor(
          of: find.text('Waiting for driver location…'),
          matching: find.byType(Column),
        ),
        findsOneWidget,
      );
    });

    // 12. Screen rebuilds identically on second pump (idempotency)
    testWidgets('widget tree is stable across two pumps', (tester) async {
      await tester.pumpWidget(
        _buildScreen(locationStream: Stream.value(null)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));
      final firstTextCount = find.byType(Text).evaluate().length;

      await tester.pumpWidget(
        _buildScreen(locationStream: Stream.value(null)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));
      final secondTextCount = find.byType(Text).evaluate().length;

      expect(secondTextCount, equals(firstTextCount));
    });
  });
}
