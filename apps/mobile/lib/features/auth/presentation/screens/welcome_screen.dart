import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:saveameal/shared/widgets/save_a_meal_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Spacing.lg),

              // Hero card
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: SaveAMealLogo(size: 60)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xl),

              // Heading
              Text(
                'Join the Movement',
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: Text(
                  'Turn food waste into community nourishment. '
                  'Start making a difference today.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: Spacing.xl),

              // Create Account button
              FilledButton(
                onPressed: () => context.go('/register'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                  backgroundColor: cs.primary,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create Account',
                      style: tt.titleMedium?.copyWith(color: cs.onPrimary),
                    ),
                    const SizedBox(width: Spacing.xs),
                    Icon(Icons.arrow_forward_rounded,
                        color: cs.onPrimary, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Log In button
              FilledButton(
                onPressed: () => context.go('/login'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                  backgroundColor: cs.surfaceContainerLowest,
                  foregroundColor: cs.onSurface,
                  elevation: 0,
                ),
                child: Text(
                  'Log In',
                  style: tt.titleMedium?.copyWith(color: cs.onSurface),
                ),
              ),
              const SizedBox(height: Spacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
