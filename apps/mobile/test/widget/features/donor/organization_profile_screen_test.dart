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
  Future<um.UserModel?> getUser(String uid) async => um.UserModel(
    uid: uid,
    name: 'FreshMart Supermarket',
    email: 'freshmart@test.com',
    role: um.UserRole.donor,
    phone: '0801234567',
    managerName: 'John Doe',
    streetAddress: '123 Test Street, Bangkok',
  );
}

// ── Router ────────────────────────────────────────────────────────────────────

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/donor/account/org',
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
              path: 'org',
              builder: (context, state) => const OrganizationProfileScreen(),
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
  group('OrganizationProfileScreen', () {
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
  });
}
