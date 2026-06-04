import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/donor_profile.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_account_repository.dart';
import 'package:saveameal/features/donor/domain/usecases/update_user_usecase.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_account_provider.dart';
import 'package:saveameal/features/donor/presentation/screens/organization_profile_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

const _testUser = AppUser(
  uid: 'abcdef1234567890',
  name: 'FreshMart Supermarket',
  email: 'freshmart@test.com',
  role: UserRole.donor,
);

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeDonorAccountRepository implements DonorAccountRepository {
  @override
  Future<void> updateUser(String uid, UserProfileUpdate update) async {}

  @override
  Future<DonorProfile?> getUser(String uid) async => DonorProfile(
    uid: uid,
    name: 'FreshMart Supermarket',
    email: 'freshmart@test.com',
    role: 'donor',
    phone: '0801234567',
    managerName: 'John Doe',
    streetAddress: '123 Test Street, Bangkok',
  );
}

class _ThrowingDonorAccountRepository implements DonorAccountRepository {
  @override
  Future<void> updateUser(String uid, UserProfileUpdate update) async {
    throw Exception('Update failed');
  }

  @override
  Future<DonorProfile?> getUser(String uid) async => DonorProfile(
    uid: uid,
    name: 'FreshMart Supermarket',
    email: 'freshmart@test.com',
    role: 'donor',
    phone: '0801234567',
    managerName: 'John Doe',
    streetAddress: '123 Test Street, Bangkok',
  );
}

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  final bool permissionDenied;
  _FakeGeolocatorPlatform({this.permissionDenied = false});

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (permissionDenied) throw const PermissionDeniedException('denied');
    return Position(
      latitude: 13.7563,
      longitude: 100.5018,
      timestamp: DateTime(2026, 6, 4),
      accuracy: 5.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }
}

class _CapturingDonorAccountRepository implements DonorAccountRepository {
  UserProfileUpdate? lastUpdate;

  @override
  Future<void> updateUser(String uid, UserProfileUpdate update) async {
    lastUpdate = update;
  }

  @override
  Future<DonorProfile?> getUser(String uid) async => DonorProfile(
    uid: uid,
    name: 'FreshMart Supermarket',
    email: 'freshmart@test.com',
    role: 'donor',
    streetAddress: '123 Test Street, Bangkok',
  );
}

class _ProfileWithCoordsDonorAccountRepository
    implements DonorAccountRepository {
  @override
  Future<void> updateUser(String uid, UserProfileUpdate update) async {}

  @override
  Future<DonorProfile?> getUser(String uid) async => DonorProfile(
    uid: uid,
    name: 'FreshMart Supermarket',
    email: 'freshmart@test.com',
    role: 'donor',
    streetAddress: '123 Test Street, Bangkok',
    latitude: 13.7563,
    longitude: 100.5018,
  );
}

// ── Router ────────────────────────────────────────────────────────────────────

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/donor/account/org',
  routes: [
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const Scaffold(body: Text('Notifications')),
    ),
    GoRoute(
      path: '/donor',
      builder: (context, state) => const Scaffold(body: Text('Donor Home')),
      routes: [
        GoRoute(
          path: 'account',
          builder: (context, state) =>
              const Scaffold(body: Text('Account Screen')),
          routes: [
            GoRoute(
              path: 'org',
              builder: (context, state) => const OrganizationProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

Widget _buildApp({DonorAccountRepository? repo}) {
  final effectiveRepo = repo ?? _FakeDonorAccountRepository();
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
      currentUserProvider.overrideWith(
        (ref) async => effectiveRepo.getUser(_testUser.uid),
      ),
      updateUserUsecaseProvider.overrideWithValue(
        UpdateUserUsecase(effectiveRepo),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: _buildRouter(),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('OrganizationProfileScreen', () {
    setUp(() {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform();
    });

    tearDown(() {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform();
    });

    testWidgets('renders AppBar with Organization Profile title', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Organization Profile'), findsWidgets);
    });

    testWidgets('renders notification bell icon in AppBar', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('renders back arrow', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('renders Store ID with uid prefix', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.textContaining('Store ID: #abcdef12'), findsOneWidget);
    });

    testWidgets('renders Store Details card', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Store Details'), findsOneWidget);
    });

    testWidgets('renders Supermarket Name field', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Supermarket Name'),
        findsOneWidget,
      );
    });

    testWidgets('renders Manager Name field', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Manager Name'),
        findsOneWidget,
      );
    });

    testWidgets('renders Primary Contact Email field', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Primary Contact Email'),
        findsOneWidget,
      );
    });

    testWidgets('renders Phone Number field', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Phone Number'),
        findsOneWidget,
      );
    });

    testWidgets('renders Street Address field', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Street Address'),
        findsOneWidget,
      );
    });

    testWidgets('renders Operating Hours card', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Operating Hours'), findsOneWidget);
    });

    testWidgets('renders operating hours rows', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Monday–Friday'), findsOneWidget);
      expect(find.text('Saturday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
    });

    testWidgets('renders Surplus Types card', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Surplus Types'), findsOneWidget);
    });

    testWidgets('renders surplus type chips', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Bakery'), findsOneWidget);
      expect(find.text('Produce'), findsOneWidget);
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text('Non-Perishable'), findsOneWidget);
    });

    testWidgets('tapping a chip selects it', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final bakeryChip = find.widgetWithText(FilterChip, 'Bakery');
      await tester.ensureVisible(bakeryChip);
      await tester.pumpAndSettle();

      expect(tester.widget<FilterChip>(bakeryChip).selected, isFalse);

      await tester.tap(bakeryChip);
      await tester.pump();

      expect(tester.widget<FilterChip>(bakeryChip).selected, isTrue);
    });

    testWidgets('renders Save Changes button', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Save Changes'), findsOneWidget);
    });

    testWidgets('Save Changes calls usecase and shows Changes saved snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(FilledButton, 'Save Changes');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Changes saved'), findsOneWidget);
    });

    testWidgets('Save Changes shows error snackbar when usecase throws', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(repo: _ThrowingDonorAccountRepository()),
      );
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(FilledButton, 'Save Changes');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Save failed. Please try again.'), findsOneWidget);
    });

    testWidgets('tapping edit on Operating Hours enters edit mode', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Scroll until the Operating Hours edit button is visible
      await tester.scrollUntilVisible(
        find.text('Operating Hours'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Find the edit IconButton that is a descendant of the row containing
      // the 'Operating Hours' text (i.e. in the header row of the card).
      final editInHoursHeader = find.descendant(
        of: find.ancestor(
          of: find.text('Operating Hours'),
          matching: find.byType(Row),
        ),
        matching: find.byIcon(Icons.edit),
      );
      await tester.ensureVisible(editInHoursHeader);
      await tester.pumpAndSettle();

      await tester.tap(editInHoursHeader);
      await tester.pumpAndSettle();

      // Verify edit mode: 'Day' TextFormField appears
      expect(find.widgetWithText(TextFormField, 'Day'), findsWidgets);

      // Scroll to Done button and tap it to exit edit mode
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Done'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();

      // Verify view mode: 'Day' TextField gone
      expect(find.widgetWithText(TextFormField, 'Day'), findsNothing);
    });

    testWidgets(
      'map button disabled when profile has no address and no coords',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
              currentUserProvider.overrideWith(
                (ref) async => const DonorProfile(
                  uid: 'abcdef1234567890',
                  name: 'FreshMart Supermarket',
                  email: 'freshmart@test.com',
                  role: 'donor',
                ),
              ),
              updateUserUsecaseProvider.overrideWithValue(
                UpdateUserUsecase(_FakeDonorAccountRepository()),
              ),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: _buildRouter(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final mapIcon = find.byIcon(Icons.map_outlined);
        await tester.ensureVisible(mapIcon);
        await tester.pumpAndSettle();
        final mapBtn = find.ancestor(
          of: mapIcon,
          matching: find.byType(IconButton),
        );
        expect(tester.widget<IconButton>(mapBtn).onPressed, isNull);
      },
    );

    testWidgets('map button enabled when profile has stored coordinates', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(repo: _ProfileWithCoordsDonorAccountRepository()),
      );
      await tester.pumpAndSettle();

      final mapIcon = find.byIcon(Icons.map_outlined);
      await tester.ensureVisible(mapIcon);
      await tester.pumpAndSettle();
      final mapBtn = find.ancestor(
        of: mapIcon,
        matching: find.byType(IconButton),
      );
      expect(tester.widget<IconButton>(mapBtn).onPressed, isNotNull);
    });

    testWidgets('location button shows snackbar on permission denied', (
      tester,
    ) async {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
        permissionDenied: true,
      );

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final locationIcon = find.byIcon(Icons.my_location);
      await tester.ensureVisible(locationIcon);
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(of: locationIcon, matching: find.byType(IconButton)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(
          'Location permission denied. Please enter your address manually.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Save Changes sends lat/lng in UserProfileUpdate', (
      tester,
    ) async {
      final capturingRepo = _CapturingDonorAccountRepository();
      await tester.pumpWidget(_buildApp(repo: capturingRepo));
      await tester.pumpAndSettle();

      final locationIcon = find.byIcon(Icons.my_location);
      await tester.ensureVisible(locationIcon);
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(of: locationIcon, matching: find.byType(IconButton)),
      );
      await tester.pumpAndSettle();

      final saveBtn = find.widgetWithText(FilledButton, 'Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(capturingRepo.lastUpdate?.latitude, closeTo(13.7563, 0.0001));
      expect(capturingRepo.lastUpdate?.longitude, closeTo(100.5018, 0.0001));
    });

    testWidgets(
      'pre-fills lat/lng from existing profile — map button enabled',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(repo: _ProfileWithCoordsDonorAccountRepository()),
        );
        await tester.pumpAndSettle();

        final mapIcon = find.byIcon(Icons.map_outlined);
        await tester.ensureVisible(mapIcon);
        await tester.pumpAndSettle();
        final mapBtn = find.ancestor(
          of: mapIcon,
          matching: find.byType(IconButton),
        );
        expect(tester.widget<IconButton>(mapBtn).onPressed, isNotNull);
      },
    );
  });
}
