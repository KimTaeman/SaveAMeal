import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_profile_provider.dart';
import 'package:saveameal/features/driver/presentation/screens/driver_vehicle_details_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _testProfile = DriverProfile(
  uid: 'test-driver-uid',
  name: 'John Driver',
  email: 'john@driver.com',
  vehicleType: 'Toyota Prius',
  licensePlate: 'ABC-1234',
  vehicleColor: 'Silver',
  cargoCapacity: 'Medium',
  refrigeratedStorage: false,
  insurancePolicyNumber: 'POL-9999',
);

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildApp({DriverProfile? profile = _testProfile}) {
  final router = GoRouter(
    initialLocation: '/vehicle-details',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (context, state) =>
            const Scaffold(body: Text('Notifications')),
      ),
      GoRoute(
        path: '/vehicle-details',
        builder: (context, state) => const DriverVehicleDetailsScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      driverProfileProvider.overrideWith(
        () => _FakeDriverProfileNotifier(profile: profile),
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

class _FakeDriverProfileNotifier extends DriverProfileNotifier {
  _FakeDriverProfileNotifier({this.profile});
  final DriverProfile? profile;

  @override
  Future<DriverProfile?> build() async => profile;

  @override
  Future<void> updateProfile(DriverProfile profile) async {
    state = AsyncData(profile);
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('DriverVehicleDetailsScreen', () {
    testWidgets('renders Vehicle Details title', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Vehicle Details'), findsOneWidget);
    });

    testWidgets('renders subtitle text', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.textContaining('coordinate efficient food pickups'),
        findsOneWidget,
      );
    });

    testWidgets('renders back button in AppBar', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('renders notification bell icon', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('renders Make & Model field pre-populated', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Toyota Prius'),
        findsOneWidget,
      );
    });

    testWidgets('renders License Plate field pre-populated', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      // The field value and hint text may both match the same string; verify
      // at least one TextFormField ancestor contains it.
      expect(
        find.widgetWithText(TextFormField, 'ABC-1234'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('renders Vehicle Color field pre-populated', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Silver'), findsOneWidget);
    });

    testWidgets('renders Cargo Capacity dropdown', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('renders Refrigerated Storage switch', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Refrigerated Storage'), findsOneWidget);
      expect(find.text('Required for cold chain rescues'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('renders Insurance Policy Number field pre-populated', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'POL-9999'), findsOneWidget);
    });

    testWidgets('renders Save button', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows offline message when profile is null', (tester) async {
      await tester.pumpWidget(_buildApp(profile: null));
      await tester.pumpAndSettle();
      expect(find.text('Profile unavailable offline'), findsOneWidget);
    });

    testWidgets('renders bottom nav bar', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('toggling refrigerated storage switch changes state', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final switchWidget = find.byType(Switch);
      final switchBefore = tester.widget<Switch>(switchWidget).value;

      await tester.tap(switchWidget);
      await tester.pump();

      final switchAfter = tester.widget<Switch>(switchWidget).value;
      expect(switchAfter, isNot(switchBefore));
    });
  });
}
