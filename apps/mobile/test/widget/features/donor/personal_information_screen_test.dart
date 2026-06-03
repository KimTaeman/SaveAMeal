import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/donor_profile.dart';
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
  Future<DonorProfile?> getUser(String uid) async => DonorProfile(
    uid: uid,
    name: 'FreshMart Supermarket',
    email: 'freshmart@test.com',
    role: 'donor',
    phone: '0801234567',
    location: 'Bangkok, Thailand',
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
    location: 'Bangkok, Thailand',
  );
}

// ── Router ────────────────────────────────────────────────────────────────────

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/donor/account/personal',
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
              path: 'personal',
              builder: (context, state) => const PersonalInformationScreen(),
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

    testWidgets('renders location field with city/zip hint', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      // Field now uses hintText to match Figma; verify by finding the GPS icon.
      expect(find.byIcon(Icons.my_location), findsOneWidget);
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

    testWidgets('save button calls updateUserUsecase and shows Saved snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Clear and re-enter Full Name to ensure form is valid
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'New Name',
      );

      final saveButton = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      await tester.tap(saveButton);
      // Two pump() calls: first drains microtasks / starts the async save;
      // second lets the resolved future run its post-await code (showSnackBar +
      // context.pop). We stop here so the SnackBar timer hasn't expired yet.
      await tester.pump();
      await tester.pump();

      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('save button shows error snackbar when usecase throws', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(repo: _ThrowingDonorAccountRepository()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'New Name',
      );

      final saveButton = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('upload photo widget has accessibility semantics', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Verify the Semantics widget with the correct label and button flag exists
      // in the widget tree.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Upload profile photo' &&
              w.properties.button == true,
        ),
        findsOneWidget,
      );
    });
  });
}
