import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_profile_provider.dart';
import 'package:saveameal/features/driver/presentation/screens/driver_edit_profile_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _testProfile = DriverProfile(
  uid: 'test-driver-uid',
  name: 'John Driver',
  email: 'john@driver.com',
  phone: '+66 812 345 678',
  primaryLocation: 'Bangkok, Thailand',
);

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildApp({DriverProfile? profile = _testProfile}) {
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
  });
}
