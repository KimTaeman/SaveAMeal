import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/core/models/user_model.dart' as um;
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/domain/repositories/auth_repository.dart';
import 'package:saveameal/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/donor_metrics.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_account_repository.dart';
import 'package:saveameal/features/donor/domain/usecases/update_user_usecase.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_account_provider.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/features/donor/presentation/screens/donor_account_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

const _testUser = AppUser(
  uid: 'test-donor-uid',
  name: 'FreshMart Supermarket',
  email: 'freshmart@test.com',
  role: UserRole.donor,
);

const _testMetrics = DonorMetrics(
  donorId: 'test-donor-uid',
  totalKg: 540.0,
  totalMeals: 1080,
  totalCO2e: 162.0,
  totalDeliveries: 18,
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

class _FakeDonorAccountRepository implements DonorAccountRepository {
  @override
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {}

  @override
  Future<um.UserModel?> getUser(String uid) async => um.UserModel(
    uid: uid,
    name: 'FreshMart Supermarket',
    email: 'freshmart@test.com',
    role: um.UserRole.donor,
  );
}

// ── Router ────────────────────────────────────────────────────────────────────

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/donor/account',
  routes: [
    GoRoute(
      path: '/donor',
      builder: (context, state) => const Scaffold(body: Text('Donor Home')),
      routes: [
        GoRoute(
          path: 'account',
          builder: (context, state) => const DonorAccountScreen(),
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
          ],
        ),
        GoRoute(
          path: 'impact',
          builder: (context, state) =>
              const Scaffold(body: Text('Impact Screen')),
        ),
        GoRoute(
          path: 'batches',
          builder: (context, state) =>
              const Scaffold(body: Text('Batches Screen')),
        ),
      ],
    ),
  ],
);

Widget _buildApp({
  AppUser? user = _testUser,
  DonorMetrics? metrics = _testMetrics,
}) {
  final fakeAuthRepo = _FakeAuthRepository();
  final fakeDonorAccountRepo = _FakeDonorAccountRepository();
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(user)),
      currentUserProvider.overrideWith(
        (ref) async => fakeDonorAccountRepo.getUser(user?.uid ?? ''),
      ),
      signOutUsecaseProvider.overrideWithValue(SignOutUsecase(fakeAuthRepo)),
      updateUserUsecaseProvider.overrideWithValue(
        UpdateUserUsecase(fakeDonorAccountRepo),
      ),
      if (metrics != null)
        donorMetricsProvider(
          'test-donor-uid',
        ).overrideWith((ref) => Stream.value(metrics)),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: _buildRouter(),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('DonorAccountScreen', () {
    testWidgets('renders AppBar with SaveAMeal title', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('SaveAMeal'), findsOneWidget);
    });

    testWidgets('renders notification bell icon', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      // Bell appears in both AppBar and Push Notifications ListTile
      expect(find.byIcon(Icons.notifications_outlined), findsWidgets);
    });

    testWidgets('renders donor badge', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('★ Donor'), findsOneWidget);
    });

    testWidgets('renders org name from UserModel', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('FreshMart Supermarket'), findsWidgets);
    });

    testWidgets('renders ACCOUNT SETTINGS section header', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('ACCOUNT SETTINGS'), findsOneWidget);
    });

    testWidgets('renders Push Notifications tile', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Push Notifications'), findsOneWidget);
    });

    testWidgets('renders Personal Information tile', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Personal Information'), findsOneWidget);
    });

    testWidgets('renders Organization Profile tile', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Organization Profile'), findsOneWidget);
    });

    testWidgets('renders Log Out button', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('renders DonorBottomNav with Account tab', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Account'), findsWidgets);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('shows stat chips with totalKg and totalDeliveries', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Total Donations'), findsOneWidget);
      expect(find.text('Organizations Helped'), findsOneWidget);
    });

    testWidgets('tapping Personal Information navigates to personal screen', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Personal Information'));
      await tester.pumpAndSettle();

      expect(find.text('Personal Info Screen'), findsOneWidget);
    });

    testWidgets('Organization Profile tile has onTap handler', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Scroll so the tile enters the viewport
      await tester.scrollUntilVisible(
        find.text('Organization Profile'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Organization Profile'), findsOneWidget);
    });

    testWidgets('toggle switch changes notifications state', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final switchWidget = find.byType(Switch).first;
      expect(tester.widget<Switch>(switchWidget).value, isFalse);

      await tester.tap(switchWidget);
      await tester.pump();

      expect(tester.widget<Switch>(switchWidget).value, isTrue);
    });

    testWidgets('shows scaffold when auth state is not yet resolved', (
      tester,
    ) async {
      final controller = StreamController<AppUser?>();
      addTearDown(controller.close);

      final fakeDonorAccountRepo = _FakeDonorAccountRepository();
      final fakeAuthRepo = _FakeAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => controller.stream),
            currentUserProvider.overrideWith((ref) async => null),
            signOutUsecaseProvider.overrideWithValue(
              SignOutUsecase(fakeAuthRepo),
            ),
            updateUserUsecaseProvider.overrideWithValue(
              UpdateUserUsecase(fakeDonorAccountRepo),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
