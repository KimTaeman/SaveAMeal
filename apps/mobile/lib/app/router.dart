import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/auth/presentation/screens/login_screen.dart';
import 'package:saveameal/features/auth/presentation/screens/register_screen.dart';
import 'package:saveameal/features/auth/presentation/screens/role_router_screen.dart';
import 'package:saveameal/features/auth/presentation/screens/welcome_screen.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart';
import 'package:saveameal/features/donor/presentation/screens/donor_dashboard_screen.dart';
import 'package:saveameal/features/driver/presentation/screens/driver_map_screen.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  final notifier = _AuthChangeNotifier(ref);
  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: notifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isPublic =
          loc == '/welcome' || loc == '/login' || loc == '/register';
      if (!notifier.isAuthenticated && !isPublic) return '/welcome';
      if (notifier.isAuthenticated && isPublic) return '/role-router';
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/role-router',
        builder: (context, state) => const RoleRouterScreen(),
      ),
      GoRoute(
        path: '/donor',
        builder: (context, state) => const DonorDashboardScreen(),
      ),
      GoRoute(
        path: '/driver',
        builder: (context, state) => const DriverMapScreen(),
      ),
      GoRoute(
        path: '/beneficiary',
        builder: (context, state) => const BeneficiaryDashboardScreen(),
      ),
    ],
  );
}

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    _isAuthenticated = switch (ref.read(authStateProvider)) {
      AsyncData(:final value) => value != null,
      _ => false,
    };
    ref.listen<AsyncValue<AppUser?>>(authStateProvider, (_, next) {
      final newValue = switch (next) {
        AsyncData(:final value) => value != null,
        _ => false,
      };
      if (newValue != _isAuthenticated) {
        _isAuthenticated = newValue;
        notifyListeners();
      }
    });
  }

  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
}
