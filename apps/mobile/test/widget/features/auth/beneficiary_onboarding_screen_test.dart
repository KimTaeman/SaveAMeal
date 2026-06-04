import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/auth/presentation/screens/beneficiary_onboarding_screen.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_org_profile_update.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_profile.dart';
import 'package:saveameal/features/beneficiary/domain/entities/order_history_entry.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_account_repository.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/update_org_profile_usecase.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_account_provider.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _testUser = AppUser(
  uid: 'u2',
  name: 'Org Tester',
  email: 'org@test.com',
  role: UserRole.beneficiary,
);

// ── Fakes ──────────────────────────────────────────────────────────────────────

class _FakeBeneficiaryRepo implements BeneficiaryAccountRepository {
  _FakeBeneficiaryRepo({this.shouldThrow = false});
  final bool shouldThrow;

  @override
  Stream<BeneficiaryProfile?> watchProfile(String uid) => Stream.value(null);

  @override
  Future<void> updatePersonalInfo(String uid, UserProfileUpdate u) async {}

  @override
  Future<void> updateOrgProfile(
    String uid,
    BeneficiaryOrgProfileUpdate u,
  ) async {
    if (shouldThrow) throw Exception('Firestore write failed');
  }

  @override
  Stream<List<OrderHistoryEntry>> watchOrderHistory(
    String uid, {
    String? cursor,
    int limit = 10,
  }) => Stream.value(const []);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/onboarding/beneficiary',
  routes: [
    GoRoute(
      path: '/onboarding/beneficiary',
      builder: (context, state) => const BeneficiaryOnboardingScreen(),
    ),
    GoRoute(
      path: '/beneficiary',
      builder: (context, state) =>
          const Scaffold(body: Text('Beneficiary Home')),
    ),
  ],
);

/// Builds the app using ProviderScope (for tests that do not need authStateProvider
/// to be in AsyncData at button-press time: renders, skip, and validation tests).
Widget _buildApp({bool repoThrows = false}) {
  final repo = _FakeBeneficiaryRepo(shouldThrow: repoThrows);
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) {
        ref.keepAlive();
        return Stream.value(_testUser);
      }),
      updateOrgProfileUseCaseProvider.overrideWithValue(
        UpdateOrgProfileUseCase(repo),
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
/// The beneficiary submit path reads `authStateProvider` synchronously. Because
/// the provider is auto-dispose and nobody watches it in the screen widget tree,
/// ProviderScope may dispose and reinitialise it as AsyncLoading by the time
/// the button is tapped.  Pre-listening the container forces the stream to emit
/// and maintains an active listener so the provider is never disposed.
///
/// Returns the widget and the container so the caller can register a tearDown.
(Widget, ProviderContainer) _buildAppWithContainer({bool repoThrows = false}) {
  final repo = _FakeBeneficiaryRepo(shouldThrow: repoThrows);
  final container = ProviderContainer(
    overrides: [
      authStateProvider.overrideWith((ref) {
        ref.keepAlive();
        return Stream.value(_testUser);
      }),
      updateOrgProfileUseCaseProvider.overrideWithValue(
        UpdateOrgProfileUseCase(repo),
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
  group('BeneficiaryOnboardingScreen', () {
    testWidgets('renders title and buttons', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Set Up Your Organization'), findsOneWidget);
      expect(find.text('Complete Setup'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);
    });

    testWidgets('skip navigates to /beneficiary', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.ensureVisible(find.text('Skip for now'));
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Beneficiary Home'), findsOneWidget);
    });

    testWidgets('empty submit shows validation error for org name', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.ensureVisible(find.text('Complete Setup'));
      await tester.tap(find.text('Complete Setup'));
      await tester.pump();
      expect(find.text('Organization name is required'), findsOneWidget);
    });

    testWidgets('valid submit navigates to /beneficiary', (tester) async {
      final (widget, container) = _buildAppWithContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Bangkok Food Bank',
      );
      // Select org type via FormFieldState.didChange (avoids overlay flakiness)
      tester
          .state<FormFieldState<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .didChange('Food Bank');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(1), '123 Main St');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'contact@bank.org',
      );
      await tester.ensureVisible(find.text('Complete Setup'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Complete Setup'));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Beneficiary Home'), findsOneWidget);
    });

    testWidgets('save failure shows error snackbar', (tester) async {
      final (widget, container) = _buildAppWithContainer(repoThrows: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Bangkok Food Bank',
      );
      // Select org type via FormFieldState.didChange (avoids overlay flakiness)
      tester
          .state<FormFieldState<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .didChange('Food Bank');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(1), '123 Main St');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'contact@bank.org',
      );
      await tester.ensureVisible(find.text('Complete Setup'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Complete Setup'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Failed to save. Please try again.'), findsOneWidget);
    });
  });
}
