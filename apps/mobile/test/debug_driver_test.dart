import 'dart:async';
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

const _testUser = AppUser(
  uid: 'u1',
  name: 'Test',
  email: 't@t.com',
  role: UserRole.driver,
);

class _FakeDriverProfileNotifier extends DriverProfileNotifier {
  @override
  Future<DriverProfile?> build() async => null;
  @override
  Future<void> updateProfile(DriverProfile profile) async {
    state = AsyncData(profile);
  }
}

void main() {
  testWidgets('auth state debug test', (tester) async {
    late final StreamController<AppUser?> authController;

    final router = GoRouter(
      initialLocation: '/onboarding/driver',
      routes: [
        GoRoute(
          path: '/onboarding/driver',
          builder: (c, s) => const DriverOnboardingScreen(),
        ),
        GoRoute(
          path: '/driver',
          builder: (c, s) => const Scaffold(body: Text('Driver Home')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) {
            ref.keepAlive(); // Prevent auto-dispose
            authController = StreamController<AppUser?>();
            ref.onDispose(authController.close);
            Future.microtask(() => authController.add(_testUser));
            return authController.stream;
          }),
          driverProfileProvider.overrideWith(
            () => _FakeDriverProfileNotifier(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Enter make and model + license
    await tester.enterText(find.byType(TextFormField).at(0), 'Toyota');
    await tester.enterText(find.byType(TextFormField).at(1), 'ABC-1234');

    // Scroll to dropdown and select
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Small').last);
    await tester.pumpAndSettle();

    // Submit using FilledButton
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final items3 = tester.widgetList<Text>(find.byType(Text));
    for (final t in items3) {
      print('TEXT AFTER SUBMIT: ${t.data}');
    }

    expect(find.text('Driver Home'), findsOneWidget);
  });
}
