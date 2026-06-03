import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/auth/presentation/screens/login_screen.dart';
import 'package:saveameal/features/auth/presentation/screens/register_screen.dart';
import 'package:saveameal/features/auth/presentation/screens/role_router_screen.dart';
import 'package:saveameal/features/auth/presentation/screens/welcome_screen.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/beneficiary_impact_screen.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/delivery_detail_screen.dart';
import 'package:saveameal/features/donor/presentation/screens/batch_qr_screen.dart';
import 'package:saveameal/features/donor/presentation/screens/batch_summary_screen.dart';
import 'package:saveameal/features/donor/presentation/screens/donor_dashboard_screen.dart';
import 'package:saveameal/features/donor/presentation/screens/log_surplus_form_screen.dart';
import 'package:saveameal/features/donor/presentation/screens/scanner_screen.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/screens/claim_rescue_screen.dart';
import 'package:saveameal/features/driver/presentation/screens/delivery_completed_screen.dart';
import 'package:saveameal/features/driver/presentation/screens/driver_map_screen.dart';
import 'package:saveameal/features/driver/presentation/screens/job_detail_screen.dart';
import 'package:saveameal/features/driver/presentation/screens/pickup_verification_screen.dart';
import 'package:saveameal/features/driver/presentation/screens/safety_verification_screen.dart';
import 'package:saveameal/features/driver/presentation/screens/verify_delivery_screen.dart';
import 'package:saveameal/features/volunteer/presentation/screens/volunteer_delivery_scanner_screen.dart';
import 'package:saveameal/features/volunteer/presentation/screens/volunteer_queue_screen.dart';

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
        routes: [
          GoRoute(
            path: 'log',
            builder: (context, state) => const ScannerScreen(),
            routes: [
              GoRoute(
                path: 'form',
                builder: (context, state) {
                  final extra = state.extra as Map<String, String?>?;
                  return LogSurplusFormScreen(
                    prefillBarcode: extra?['barcode'],
                    prefillName: extra?['name'],
                  );
                },
              ),
              GoRoute(
                path: 'summary',
                builder: (context, state) => const BatchSummaryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'batch/:batchId/qr',
            builder: (context, state) =>
                BatchQrScreen(batchId: state.pathParameters['batchId']!),
          ),
          GoRoute(
            path: 'impact',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Impact'))),
          ),
          GoRoute(
            path: 'batches',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('All Batches'))),
          ),
          GoRoute(
            path: 'account',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Account'))),
          ),
        ],
      ),
      GoRoute(
        path: '/driver',
        builder: (context, state) => const DriverMapScreen(),
        routes: [
          GoRoute(
            path: 'job/:batchId',
            builder: (context, state) =>
                JobDetailScreen(batch: state.extra! as BatchSummary),
          ),
          GoRoute(
            path: 'rescue',
            builder: (context, state) => const ClaimRescueScreen(),
          ),
          GoRoute(
            path: 'pickup-verify',
            builder: (context, state) => const PickupVerificationScreen(),
          ),
          GoRoute(
            path: 'safety',
            builder: (context, state) => const SafetyVerificationScreen(),
          ),
          GoRoute(
            path: 'verify-delivery',
            builder: (context, state) => const VerifyDeliveryScreen(),
          ),
          GoRoute(
            path: 'completed',
            builder: (context, state) => const DeliveryCompletedScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/beneficiary',
        builder: (context, state) => const BeneficiaryHomeScreen(),
        routes: [
          GoRoute(
            path: 'delivery/:batchId',
            builder: (context, state) =>
                DeliveryDetailScreen(batchId: state.pathParameters['batchId']!),
          ),
          GoRoute(
            path: 'impact',
            builder: (context, state) => const BeneficiaryImpactScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/volunteer',
        builder: (context, state) => const VolunteerQueueScreen(),
        routes: [
          GoRoute(
            path: 'scan/:batchId',
            builder: (context, state) => VolunteerDeliveryScannerScreen(
              batchId: state.pathParameters['batchId']!,
            ),
          ),
        ],
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
