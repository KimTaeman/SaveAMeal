import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class RoleRouterScreen extends ConsumerStatefulWidget {
  const RoleRouterScreen({super.key});

  @override
  ConsumerState<RoleRouterScreen> createState() => _RoleRouterScreenState();
}

class _RoleRouterScreenState extends ConsumerState<RoleRouterScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;
  late final Animation<double> _counterClockwiseTurns;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _counterClockwiseTurns = Tween(
      begin: 0.0,
      end: -1.0,
    ).animate(_spinController);
    _pulseScale = Tween(begin: 1.0, end: 1.04).animate(_pulseController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(authStateProvider).whenData(_routeByRole);
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    ref.listen<AsyncValue<AppUser?>>(authStateProvider, (_, next) {
      if (!mounted) return;
      next.whenData(_routeByRole);
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, cs.primary.withValues(alpha: 0.12)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring — counter-clockwise
                    RotationTransition(
                      turns: _counterClockwiseTurns,
                      child: SizedBox(
                        width: 170,
                        height: 170,
                        child: CircularProgressIndicator(
                          value: 0.75,
                          strokeWidth: 1.5,
                          color: cs.primary.withValues(alpha: 0.20),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                    // Inner ring — clockwise
                    RotationTransition(
                      turns: _spinController,
                      child: SizedBox(
                        width: 126,
                        height: 126,
                        child: CircularProgressIndicator(
                          value: 0.70,
                          strokeWidth: 1.5,
                          color: cs.primary.withValues(alpha: 0.31),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                    // Center pulsing circle
                    ScaleTransition(
                      scale: _pulseScale,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primaryContainer,
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.16),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.local_shipping_outlined,
                          color: cs.primary,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),

              Text(
                'Routing to your\ndashboard...',
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),

              Text(
                'Preparing your personalized experience',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xl),

              SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _routeByRole(AppUser? user) {
    if (!mounted) return;
    if (user == null) {
      context.go('/login');
      return;
    }
    switch (user.role) {
      case UserRole.donor:
        context.go('/donor');
      case UserRole.driver:
        context.go('/driver');
      case UserRole.beneficiary:
        context.go('/beneficiary');
    }
  }
}
