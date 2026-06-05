import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';
import 'package:saveameal/features/donor/domain/usecases/update_user_usecase.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_account_provider.dart';
import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_profile_provider.dart';
import 'package:saveameal/features/driver/presentation/screens/driver_edit_profile_screen.dart';
import 'package:saveameal/services/location_service.dart';
import 'package:saveameal/services/service_providers.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _testProfile = DriverProfile(
  uid: 'test-driver-uid',
  name: 'John Driver',
  email: 'john@driver.com',
  phone: '+66 812 345 678',
  primaryLocation: 'Bangkok, Thailand',
);

// ── Fakes ─────────────────────────────────────────────────────────────────────

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

class _FakeLocationService extends LocationService {
  _FakeLocationService({required this.lat, required this.lng});
  final double lat;
  final double lng;

  @override
  Future<Position> getCurrentPosition() async => Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime(2024),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

class _FakeUpdateUserUsecase extends Fake implements UpdateUserUsecase {
  UserProfileUpdate? lastUpdate;

  @override
  Future<void> call(String uid, UserProfileUpdate update) async {
    lastUpdate = update;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildApp({
  DriverProfile? profile = _testProfile,
  LocationService? locationService,
  UpdateUserUsecase? updateUserUsecase,
}) {
  final router = GoRouter(
    initialLocation: '/personal-info',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (context, state) =>
            const Scaffold(body: Text('Notifications')),
      ),
      GoRoute(
        path: '/personal-info',
        builder: (context, state) => const DriverEditProfileScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      driverProfileProvider.overrideWith(
        () => _FakeDriverProfileNotifier(profile: profile),
      ),
      if (locationService != null)
        locationServiceProvider.overrideWithValue(locationService),
      if (updateUserUsecase != null)
        updateUserUsecaseProvider.overrideWithValue(updateUserUsecase),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('DriverEditProfileScreen (Personal Information)', () {
    testWidgets('renders Personal Information title', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Personal Information'), findsOneWidget);
    });

    testWidgets('renders subtitle text', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.text('Tell us a bit about yourself to get started.'),
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

    testWidgets('renders Full Name field pre-populated', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'John Driver'), findsOneWidget);
    });

    testWidgets('renders read-only Email Address field', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('john@driver.com'), findsOneWidget);
    });

    testWidgets('renders Phone Number field pre-populated', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, '+66 812 345 678'),
        findsOneWidget,
      );
    });

    testWidgets('renders Primary Location field pre-populated', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Bangkok, Thailand'),
        findsOneWidget,
      );
    });

    testWidgets('renders Save button', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows validation error when name is cleared', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'John Driver');
      await tester.tap(nameField);
      await tester.pump();
      await tester.enterText(nameField, '');
      await tester.pump();

      // Scroll to Save button and tap it
      await tester.scrollUntilVisible(
        find.text('Save'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
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

    testWidgets('renders GPS button in Primary Location field', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('tapping GPS button fills location field with coordinates', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          locationService: _FakeLocationService(lat: 13.7563, lng: 100.5018),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.my_location), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextFormField, '13.7563, 100.5018'),
        findsOneWidget,
      );
    });

    testWidgets(
      'saving after GPS tap writes coordinates via updateUserUsecase',
      (tester) async {
        final fakeUpdateUser = _FakeUpdateUserUsecase();
        await tester.pumpWidget(
          _buildApp(
            locationService: _FakeLocationService(lat: 13.7563, lng: 100.5018),
            updateUserUsecase: fakeUpdateUser,
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byIcon(Icons.my_location));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.my_location), warnIfMissed: false);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Save'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(fakeUpdateUser.lastUpdate?.latitude, closeTo(13.7563, 0.0001));
        expect(fakeUpdateUser.lastUpdate?.longitude, closeTo(100.5018, 0.0001));
      },
    );
  });
}
