import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_org_profile_update.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_profile.dart';
import 'package:saveameal/features/beneficiary/domain/entities/order_history_entry.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_account_repository.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/update_personal_info_usecase.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_account_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/beneficiary_personal_information_screen.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';
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
  phone: '081-234-5678',
  location: 'Bangkok',
);

final _testOrders = [
  OrderHistoryEntry(
    id: 'abc4092',
    date: DateTime(2023, 10, 24),
    status: OrderHistoryEntryStatus.delivered,
    itemDescription: '50 Hot Meals',
    donorName: 'Green Leaf Kitchen',
    totalWeightKg: 20.0,
    foodCategory: 'hot_meals',
  ),
];

// ── Fakes ──────────────────────────────────────────────────────────────────────

class _FakeBeneficiaryAccountRepository
    implements BeneficiaryAccountRepository {
  bool updatePersonalInfoCalled = false;
  bool updateOrgProfileCalled = false;

  @override
  Stream<BeneficiaryProfile?> watchProfile(String uid) =>
      Stream.value(_testProfile);

  @override
  Future<void> updatePersonalInfo(String uid, UserProfileUpdate update) async {
    updatePersonalInfoCalled = true;
  }

  @override
  Future<void> updateOrgProfile(
    String uid,
    BeneficiaryOrgProfileUpdate update,
  ) async {
    updateOrgProfileCalled = true;
  }

  @override
  Stream<List<OrderHistoryEntry>> watchOrderHistory(
    String uid, {
    String? cursor,
    int limit = 10,
  }) => Stream.value(_testOrders);
}

// ── Router ─────────────────────────────────────────────────────────────────────

GoRouter _buildRouter(_FakeBeneficiaryAccountRepository fakeRepo) => GoRouter(
  initialLocation: '/beneficiary/account/personal',
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
          builder: (context, state) =>
              const Scaffold(body: Text('Account Screen')),
          routes: [
            GoRoute(
              path: 'personal',
              builder: (context, state) =>
                  const BeneficiaryPersonalInformationScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('BeneficiaryPersonalInformationScreen', () {
    late _FakeBeneficiaryAccountRepository fakeRepo;

    setUp(() {
      fakeRepo = _FakeBeneficiaryAccountRepository();
    });

    testWidgets('renders without throwing', (tester) async {
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
            updatePersonalInfoUseCaseProvider.overrideWithValue(
              UpdatePersonalInfoUseCase(fakeRepo),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(fakeRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('pre-populates Full Name field with profile name', (
      tester,
    ) async {
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
            updatePersonalInfoUseCaseProvider.overrideWithValue(
              UpdatePersonalInfoUseCase(fakeRepo),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(fakeRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final nameField = find.widgetWithText(TextFormField, 'Haven Shelter');
      expect(nameField, findsOneWidget);
    });

    testWidgets('shows validation error when name is cleared and save tapped', (
      tester,
    ) async {
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
            updatePersonalInfoUseCaseProvider.overrideWithValue(
              UpdatePersonalInfoUseCase(fakeRepo),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(fakeRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear the name field
      final nameField = find.widgetWithText(TextFormField, 'Haven Shelter');
      await tester.enterText(nameField, '');

      // Scroll down until the Save button is visible, then tap
      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('location suffix icon is present', (tester) async {
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
            updatePersonalInfoUseCaseProvider.overrideWithValue(
              UpdatePersonalInfoUseCase(fakeRepo),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(fakeRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('tapping Save calls updatePersonalInfo on the repository', (
      tester,
    ) async {
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
            updatePersonalInfoUseCaseProvider.overrideWithValue(
              UpdatePersonalInfoUseCase(fakeRepo),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(fakeRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure name field has text (pre-populated from profile)
      final nameField = find.widgetWithText(TextFormField, 'Haven Shelter');
      expect(nameField, findsOneWidget);

      // Scroll to the Save button and tap it
      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fakeRepo.updatePersonalInfoCalled, isTrue);
    });
  });
}
