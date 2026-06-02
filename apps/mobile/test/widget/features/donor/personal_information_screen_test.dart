import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/core/models/user_model.dart' as um;
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_account_repository.dart';
import 'package:saveameal/features/donor/domain/usecases/update_user_usecase.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_account_provider.dart';
import 'package:saveameal/features/donor/presentation/screens/personal_information_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

const _testUser = AppUser(
  uid: 'test-donor-uid',
  name: 'FreshMart Supermarket',
  email: 'freshmart@test.com',
  role: UserRole.donor,
);

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeDonorAccountRepository implements DonorAccountRepository {
  @override
  Future<void> updateUser(String uid, UserProfileUpdate update) async {}

  @override
  Future<um.UserModel?> getUser(String uid) async => um.UserModel(
    uid: uid,
    name: 'FreshMart Supermarket',
    email: 'freshmart@test.com',
    role: um.UserRole.donor,
    phone: '0801234567',
    location: 'Bangkok, Thailand',
  );
}

// ── Router ────────────────────────────────────────────────────────────────────

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/donor/account/personal',
  routes: [
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
              path: 'personal',
              builder: (context, state) => const PersonalInformationScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

Widget _buildApp() {
  final fakeDonorAccountRepo = _FakeDonorAccountRepository();
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
      currentUserProvider.overrideWith(
        (ref) async => fakeDonorAccountRepo.getUser(_testUser.uid),
      ),
      updateUserUsecaseProvider.overrideWithValue(
        UpdateUserUsecase(fakeDonorAccountRepo),
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
  group('PersonalInformationScreen', () {
    testWidgets('renders AppBar with Donor Profile title', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Donor Profile'), findsOneWidget);
    });

    testWidgets('renders subtitle text', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.text('Tell us a bit about yourself to get started.'),
        findsOneWidget,
      );
    });

    testWidgets('renders notification bell icon in AppBar', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('renders Upload Photo widget', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Upload Photo'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('renders Full Name field', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
    });

    testWidgets('renders Email Address field', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Email Address'),
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

    testWidgets('renders Primary Location field', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Primary Location'),
        findsOneWidget,
      );
    });

    testWidgets('renders Save button', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });

    testWidgets('prefills Full Name from UserModel', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Full Name'),
          matching: find.text('FreshMart Supermarket'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('back arrow button is present', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
