import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/domain/repositories/auth_repository.dart';
import 'package:saveameal/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_profile_provider.dart';
import 'package:saveameal/features/driver/presentation/screens/driver_account_screen.dart';
import 'package:saveameal/features/driver/presentation/screens/driver_edit_profile_screen.dart';
import 'package:saveameal/features/driver/presentation/screens/driver_vehicle_details_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _testUser = AppUser(
  uid: 'test-driver-uid',
  name: 'John Driver',
  email: 'john@driver.com',
  role: UserRole.driver,
);

const _testProfile = DriverProfile(
  uid: 'test-driver-uid',
  name: 'John Driver',
  email: 'john@driver.com',
  phone: '+66 812 345 678',
  vehicleType: 'Motorcycle',
  licensePlate: 'กข 1234',
  joinDate: 'Oct 2024',
  totalPickups: 42,
);

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> watchAuthState() => const Stream.empty();

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

// ── Router ─────────────────────────────────────────────────────────────────────

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/driver/account',
  routes: [
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const Scaffold(body: Text('Notifications')),
    ),
    GoRoute(
      path: '/driver',
      builder: (context, state) => const Scaffold(body: Text('Driver Home')),
      routes: [
        GoRoute(
          path: 'account',
          builder: (context, state) => const DriverAccountScreen(),
          routes: [
            GoRoute(
              path: 'personal-info',
              builder: (context, state) => const DriverEditProfileScreen(),
            ),
            GoRoute(
              path: 'vehicle-details',
              builder: (context, state) => const DriverVehicleDetailsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildApp({DriverProfile? profile = _testProfile}) {
  final fakeAuthRepo = _FakeAuthRepository();
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
      signOutUsecaseProvider.overrideWithValue(SignOutUsecase(fakeAuthRepo)),
      driverProfileProvider.overrideWith(
        () => _FakeDriverProfileNotifier(profile: profile),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: _buildRouter(),
    ),
  );
}

class _FakeDriverProfileNotifier extends DriverProfileNotifier {
  _FakeDriverProfileNotifier({this.profile});
  final DriverProfile? profile;

  @override
  Future<DriverProfile?> build() async => profile;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('DriverAccountScreen', () {
    testWidgets('renders AppBar with SaveAMeal title', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('SaveAMeal'), findsOneWidget);
    });

    testWidgets('renders notification bell icon', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('renders Volunteer Driver badge', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Volunteer Driver'), findsOneWidget);
    });

    testWidgets('renders driver name', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('John Driver'), findsOneWidget);
    });

    testWidgets('renders JOIN DATE stat card', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('JOIN DATE'), findsOneWidget);
      expect(find.text('Oct 2024'), findsOneWidget);
    });

    testWidgets('renders TOTAL PICKUPS stat card', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('TOTAL PICKUPS'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('renders Push Notifications toggle', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('New Deliveries'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('renders Personal Information tile', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Personal Information'), findsOneWidget);
    });

    testWidgets('renders Vehicle Details tile', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Vehicle Details'), findsOneWidget);
    });

    testWidgets('renders Log Out button', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('renders bottom nav with Account tab selected', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Account'), findsWidgets);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('shows offline message when profile is null', (tester) async {
      await tester.pumpWidget(_buildApp(profile: null));
      await tester.pumpAndSettle();
      expect(find.text('Profile unavailable offline'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders scaffold body structure', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets(
      'tapping Personal Information navigates to personal-info screen',
      (tester) async {
        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Personal Information'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Personal Information'));
        await tester.pumpAndSettle();

        expect(find.byType(DriverEditProfileScreen), findsOneWidget);
      },
    );

    testWidgets('tapping Vehicle Details navigates to vehicle-details screen', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Vehicle Details'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vehicle Details'));
      await tester.pumpAndSettle();

      expect(find.byType(DriverVehicleDetailsScreen), findsOneWidget);
    });

    testWidgets('Log Out button calls signOut', (tester) async {
      bool signOutCalled = false;

      final trackingAuthRepo = _TrackingAuthRepository(
        onSignOut: () => signOutCalled = true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            signOutUsecaseProvider.overrideWithValue(
              SignOutUsecase(trackingAuthRepo),
            ),
            driverProfileProvider.overrideWith(
              () => _FakeDriverProfileNotifier(profile: _testProfile),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Log Out'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(signOutCalled, isTrue);
    });

    testWidgets('stats show dashes when profile fields are null', (
      tester,
    ) async {
      const profileWithNullStats = DriverProfile(
        uid: 'test-driver-uid',
        name: 'John Driver',
        email: 'john@driver.com',
      );
      await tester.pumpWidget(_buildApp(profile: profileWithNullStats));
      await tester.pumpAndSettle();
      expect(find.text('—'), findsWidgets);
    });
  });
}

class _TrackingAuthRepository implements AuthRepository {
  _TrackingAuthRepository({required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Stream<AppUser?> watchAuthState() => const Stream.empty();

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async => onSignOut();
}
