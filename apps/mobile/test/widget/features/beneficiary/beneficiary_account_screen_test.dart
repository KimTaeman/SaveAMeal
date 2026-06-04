import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/domain/repositories/auth_repository.dart';
import 'package:saveameal/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_profile.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_account_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/beneficiary_account_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Fixtures ───────────────────────────────────────────────────────────────────

const _testUser = AppUser(
  uid: 'test-uid',
  name: 'Haven Shelter',
  email: 'shelter@example.com',
  role: UserRole.beneficiary,
);

final _testProfile = BeneficiaryProfile(
  uid: 'test-uid',
  name: 'Haven Shelter',
  email: 'shelter@example.com',
  role: 'beneficiary',
  mealsReceived: 450,
  joinedAt: DateTime(2023, 3, 1),
  orgName: 'Haven Shelter',
  orgType: 'Shelter',
);

// ── Fakes ──────────────────────────────────────────────────────────────────────

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
  initialLocation: '/beneficiary/account',
  routes: [
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const Scaffold(body: Text('Notifications')),
    ),
    GoRoute(
      path: '/beneficiary',
      builder: (context, state) =>
          const Scaffold(body: Text('Beneficiary Home')),
      routes: [
        GoRoute(
          path: 'account',
          builder: (context, state) => const BeneficiaryAccountScreen(),
          routes: [
            GoRoute(
              path: 'personal',
              builder: (context, state) =>
                  const Scaffold(body: Text('Personal Info Screen')),
            ),
            GoRoute(
              path: 'org',
              builder: (context, state) =>
                  const Scaffold(body: Text('Org Profile Screen')),
            ),
            GoRoute(
              path: 'orders',
              builder: (context, state) =>
                  const Scaffold(body: Text('Orders Screen')),
            ),
          ],
        ),
      ],
    ),
  ],
);

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('BeneficiaryAccountScreen', () {
    testWidgets('renders without throwing', (tester) async {
      final fakeAuthRepo = _FakeAuthRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeDeliveriesProvider(
              'test-uid',
            ).overrideWith((ref) => Stream.value(const <IntakeRequest>[])),
            currentBeneficiaryProfileProvider.overrideWith(
              (ref) => Stream.value(_testProfile),
            ),
            signOutUsecaseProvider.overrideWithValue(
              SignOutUsecase(fakeAuthRepo),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows CircularProgressIndicator when profile is loading', (
      tester,
    ) async {
      final controller = StreamController<BeneficiaryProfile?>();
      addTearDown(controller.close);
      final fakeAuthRepo = _FakeAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeDeliveriesProvider(
              'test-uid',
            ).overrideWith((ref) => Stream.value(const <IntakeRequest>[])),
            currentBeneficiaryProfileProvider.overrideWith(
              (ref) => controller.stream,
            ),
            signOutUsecaseProvider.overrideWithValue(
              SignOutUsecase(fakeAuthRepo),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders profile content', (tester) async {
      final fakeAuthRepo = _FakeAuthRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeDeliveriesProvider(
              'test-uid',
            ).overrideWith((ref) => Stream.value(const <IntakeRequest>[])),
            currentBeneficiaryProfileProvider.overrideWith(
              (ref) => Stream.value(_testProfile),
            ),
            signOutUsecaseProvider.overrideWithValue(
              SignOutUsecase(fakeAuthRepo),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Haven Shelter'), findsWidgets);
      expect(find.text('BENEFICIARY'), findsOneWidget);
      expect(find.text('MEALS RECEIVED'), findsOneWidget);
      expect(find.text('450'), findsOneWidget);
      expect(find.text('ACCOUNT SETTINGS'), findsOneWidget);
    });

    testWidgets('Switch starts with value true', (tester) async {
      final fakeAuthRepo = _FakeAuthRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeDeliveriesProvider(
              'test-uid',
            ).overrideWith((ref) => Stream.value(const <IntakeRequest>[])),
            currentBeneficiaryProfileProvider.overrideWith(
              (ref) => Stream.value(_testProfile),
            ),
            signOutUsecaseProvider.overrideWithValue(
              SignOutUsecase(fakeAuthRepo),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);
    });

    testWidgets('tapping Personal Information navigates to personal screen', (
      tester,
    ) async {
      final fakeAuthRepo = _FakeAuthRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            activeDeliveriesProvider(
              'test-uid',
            ).overrideWith((ref) => Stream.value(const <IntakeRequest>[])),
            currentBeneficiaryProfileProvider.overrideWith(
              (ref) => Stream.value(_testProfile),
            ),
            signOutUsecaseProvider.overrideWithValue(
              SignOutUsecase(fakeAuthRepo),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll until the tile is fully visible before tapping
      await tester.scrollUntilVisible(
        find.text('Personal Information'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Personal Information'));
      await tester.pumpAndSettle();
      expect(find.text('Personal Info Screen'), findsOneWidget);
    });
  });
}
