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
import 'package:saveameal/features/donor/presentation/screens/donor_org_setup_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

const _testUser = AppUser(
  uid: 'uid123456789012',
  name: 'Test Donor',
  email: 'test@donor.com',
  role: UserRole.donor,
);

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeDonorAccountRepository implements DonorAccountRepository {
  @override
  Future<void> updateUser(String uid, UserProfileUpdate update) async {}

  @override
  Future<DonorProfile?> getUser(String uid) async => null;
}

class _ThrowingDonorAccountRepository implements DonorAccountRepository {
  @override
  Future<void> updateUser(String uid, UserProfileUpdate update) async {
    throw Exception('Save failed');
  }

  @override
  Future<DonorProfile?> getUser(String uid) async => null;
}

// ── Geolocator fakes ──────────────────────────────────────────────────────────

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

// ── Capturing fake ────────────────────────────────────────────────────────────

class _CapturingDonorAccountRepository implements DonorAccountRepository {
  UserProfileUpdate? lastUpdate;

  @override
  Future<void> updateUser(String uid, UserProfileUpdate update) async {
    lastUpdate = update;
  }

  @override
  Future<DonorProfile?> getUser(String uid) async => null;
}

// ── Router ────────────────────────────────────────────────────────────────────

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/donor/onboarding',
  routes: [
    GoRoute(
      path: '/donor',
      builder: (context, state) => const Scaffold(body: Text('Donor Home')),
      routes: [
        GoRoute(
          path: 'onboarding',
          builder: (context, state) => const DonorOrgSetupScreen(),
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
      currentUserProvider.overrideWith((ref) async => null),
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
  group('DonorOrgSetupScreen', () {
    setUp(() {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform();
    });

    tearDown(() {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform();
    });

    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Set Up Your Organization'), findsOneWidget);
    });

    testWidgets('renders Step 2 of 2 label', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 2'), findsOneWidget);
    });

    testWidgets('renders Organization / Store Name field', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Organization / Store Name'),
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

    testWidgets('renders all surplus type chips', (tester) async {
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

      final chip = find.widgetWithText(FilterChip, 'Bakery');
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(chip).selected, isFalse);

      await tester.tap(chip);
      await tester.pump();

      expect(tester.widget<FilterChip>(chip).selected, isTrue);
    });

    testWidgets('tapping a selected chip deselects it', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final chip = find.widgetWithText(FilterChip, 'Dairy');
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();

      await tester.tap(chip);
      await tester.pump();
      expect(tester.widget<FilterChip>(chip).selected, isTrue);

      await tester.tap(chip);
      await tester.pump();
      expect(tester.widget<FilterChip>(chip).selected, isFalse);
    });

    testWidgets('renders Complete Setup button', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final btn = find.widgetWithText(FilledButton, 'Complete Setup');
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      expect(btn, findsOneWidget);
    });

    testWidgets('renders Skip for now button', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final btn = find.widgetWithText(TextButton, 'Skip for now');
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      expect(btn, findsOneWidget);
    });

    testWidgets('shows validation error when org name is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final btn = find.widgetWithText(FilledButton, 'Complete Setup');
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('Complete Setup navigates to /donor on success', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Organization / Store Name'),
        'FreshMart Supermarket',
      );

      final btn = find.widgetWithText(FilledButton, 'Complete Setup');
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.text('Donor Home'), findsOneWidget);
    });

    testWidgets('Complete Setup shows error snackbar when save fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(repo: _ThrowingDonorAccountRepository()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Organization / Store Name'),
        'FreshMart Supermarket',
      );

      final btn = find.widgetWithText(FilledButton, 'Complete Setup');
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Failed to save profile. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('Skip for now navigates to /donor without saving', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final btn = find.widgetWithText(TextButton, 'Skip for now');
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.text('Donor Home'), findsOneWidget);
    });

    testWidgets('map button disabled when address empty and no coords', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final mapIcon = find.byIcon(Icons.map_outlined);
      await tester.ensureVisible(mapIcon);
      await tester.pumpAndSettle();

      final mapBtn = find.ancestor(
        of: mapIcon,
        matching: find.byType(IconButton),
      );
      expect(tester.widget<IconButton>(mapBtn).onPressed, isNull);
    });

    testWidgets('map button enabled after entering address text', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Street Address'),
        '123 Sukhumvit Rd, Bangkok',
      );
      await tester.pump();

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

      final locationBtn = find.byIcon(Icons.my_location);
      await tester.ensureVisible(locationBtn);
      await tester.pumpAndSettle();
      await tester.tap(locationBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(
          'Location permission denied. Please enter your address manually.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Complete Setup sends lat/lng in UserProfileUpdate', (
      tester,
    ) async {
      final capturingRepo = _CapturingDonorAccountRepository();
      await tester.pumpWidget(_buildApp(repo: capturingRepo));
      await tester.pumpAndSettle();

      // Tap location button to populate coords
      final locationBtn = find.byIcon(Icons.my_location);
      await tester.ensureVisible(locationBtn);
      await tester.pumpAndSettle();
      await tester.tap(locationBtn);
      await tester.pumpAndSettle();

      // Fill required org name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Organization / Store Name'),
        'FreshMart',
      );

      final saveBtn = find.widgetWithText(FilledButton, 'Complete Setup');
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(capturingRepo.lastUpdate?.latitude, closeTo(13.7563, 0.0001));
      expect(capturingRepo.lastUpdate?.longitude, closeTo(100.5018, 0.0001));
    });
  });
}
