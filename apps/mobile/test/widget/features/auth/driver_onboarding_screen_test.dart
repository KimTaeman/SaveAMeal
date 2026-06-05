import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/auth/presentation/screens/driver_onboarding_screen.dart';
import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_profile_provider.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _testUser = AppUser(
  uid: 'u1',
  name: 'Test',
  email: 't@t.com',
  role: UserRole.driver,
);

// ── Fakes ──────────────────────────────────────────────────────────────────────

class _FakeDriverProfileNotifier extends DriverProfileNotifier {
  _FakeDriverProfileNotifier({DriverProfile? profile}) : _profile = profile;
  final DriverProfile? _profile;

  @override
  Future<DriverProfile?> build() async => _profile;

  @override
  Future<void> updateProfile(DriverProfile profile) async {
    state = AsyncData(profile);
  }
}

class _ThrowingDriverProfileNotifier extends DriverProfileNotifier {
  @override
  Future<DriverProfile?> build() async => null;

  @override
  Future<void> updateProfile(DriverProfile profile) async {
    throw Exception('Firestore write failed');
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/onboarding/driver',
  routes: [
    GoRoute(
      path: '/onboarding/driver',
      builder: (context, state) => const DriverOnboardingScreen(),
    ),
    GoRoute(
      path: '/driver',
      builder: (context, state) => const Scaffold(body: Text('Driver Home')),
    ),
  ],
);

/// Builds the app using ProviderScope (for tests that do not need authStateProvider
/// to be in AsyncData at button-press time: renders, skip, and validation tests).
Widget _buildApp({DriverProfileNotifier Function()? notifierFactory}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) {
        ref.keepAlive();
        return Stream.value(_testUser);
      }),
      driverProfileProvider.overrideWith(
        notifierFactory ?? () => _FakeDriverProfileNotifier(),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: _buildRouter(),
    ),
  );
}

/// Builds the app using UncontrolledProviderScope with a pre-primed container.
///
/// The driver submit path reads `authStateProvider` synchronously. Because the
/// provider is auto-dispose and nobody watches it in the screen widget tree,
/// ProviderScope may dispose and reinitialise it as AsyncLoading by the time
/// the button is tapped.  Pre-listening the container forces the stream to emit
/// and maintains an active listener so the provider is never disposed.
///
/// Returns the widget and the container so the caller can register a tearDown.
(Widget, ProviderContainer) _buildAppWithContainer({
  DriverProfileNotifier Function()? notifierFactory,
}) {
  final container = ProviderContainer(
    overrides: [
      authStateProvider.overrideWith((ref) {
        ref.keepAlive();
        return Stream.value(_testUser);
      }),
      driverProfileProvider.overrideWith(
        notifierFactory ?? () => _FakeDriverProfileNotifier(),
      ),
    ],
  );
  // Keep authStateProvider alive and force its stream to emit.
  container.listen(authStateProvider, (prev, next) {}, fireImmediately: true);

  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: _buildRouter(),
    ),
  );
  return (widget, container);
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('DriverOnboardingScreen', () {
    testWidgets('renders title and buttons', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Set Up Your Vehicle'), findsOneWidget);
      expect(find.text('Complete Setup'), findsOneWidget);
    });

    testWidgets('empty submit shows validation errors', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.ensureVisible(find.text('Complete Setup'));
      await tester.tap(find.text('Complete Setup'));
      await tester.pump();
      expect(find.text('Make & model is required'), findsOneWidget);
      expect(find.text('License plate is required'), findsOneWidget);
    });

    testWidgets('valid submit navigates to /driver', (tester) async {
      final (widget, container) = _buildAppWithContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.enterText(find.byType(TextFormField).at(0), 'Toyota Prius');
      await tester.enterText(find.byType(TextFormField).at(1), 'ABC-1234');
      // Select cargo capacity via FormFieldState.didChange (avoids overlay flakiness)
      tester
          .state<FormFieldState<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .didChange('Small');
      await tester.pump();
      await tester.ensureVisible(find.text('Complete Setup'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Complete Setup'));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Driver Home'), findsOneWidget);
    });

    testWidgets('save failure shows error snackbar', (tester) async {
      final (widget, container) = _buildAppWithContainer(
        notifierFactory: () => _ThrowingDriverProfileNotifier(),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.enterText(find.byType(TextFormField).at(0), 'Toyota Prius');
      await tester.enterText(find.byType(TextFormField).at(1), 'ABC-1234');
      // Select cargo capacity via FormFieldState.didChange (avoids overlay flakiness)
      tester
          .state<FormFieldState<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .didChange('Small');
      await tester.pump();
      await tester.ensureVisible(find.text('Complete Setup'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Complete Setup'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Failed to save. Please try again.'), findsOneWidget);
    });
  });
}
