import 'package:flutter/material.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

/// A horizontal step indicator for multi-step onboarding flows.
///
/// Each step is rendered as a circle; steps are connected by lines.
/// - Completed steps: filled with [AppColors.brand] + checkmark icon.
/// - Current step: filled with [AppColors.brand] (no checkmark).
/// - Future steps: outlined circle with [ColorScheme.outline].
/// - Connector lines: filled with [AppColors.brand] when the step to the left
///   is completed, [ColorScheme.outlineVariant] otherwise.
class OnboardingStepIndicator extends StatelessWidget {
  const OnboardingStepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  /// Total number of steps in the flow.
  final int totalSteps;

  /// The active step (1-based).
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          'Step $currentStep of $totalSteps',
          style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: Spacing.sm),
        // Dots + connectors row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 1; i <= totalSteps; i++) ...[
              _StepDot(
                step: i,
                currentStep: currentStep,
                totalSteps: totalSteps,
                brandColor: ac.brand,
                outlineColor: cs.outline,
                onBrandColor: cs.onPrimary,
              ),
              if (i < totalSteps)
                _StepConnector(
                  completed: i < currentStep,
                  brandColor: ac.brand,
                  outlineVariantColor: cs.outlineVariant,
                ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Private helpers ─────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.step,
    required this.currentStep,
    required this.totalSteps,
    required this.brandColor,
    required this.outlineColor,
    required this.onBrandColor,
  });

  final int step;
  final int currentStep;
  final int totalSteps;
  final Color brandColor;
  final Color outlineColor;
  final Color onBrandColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isCompleted = step < currentStep;
    final isCurrent = step == currentStep;

    const double size = 28;

    if (isCompleted) {
      return Semantics(
        label: 'Step $step of $totalSteps, completed',
        excludeSemantics: true,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: brandColor),
          child: Icon(Icons.check, color: onBrandColor, size: 16),
        ),
      );
    }

    if (isCurrent) {
      return Semantics(
        label: 'Step $step of $totalSteps, current',
        excludeSemantics: true,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: brandColor),
          child: Center(
            child: Text(
              '$step',
              style: tt.labelSmall?.copyWith(
                color: onBrandColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    // Future step — outlined circle
    return Semantics(
      label: 'Step $step of $totalSteps, not started',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: outlineColor, width: 1.5),
        ),
        child: Center(
          child: Text(
            '$step',
            style: tt.labelSmall?.copyWith(
              color: outlineColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({
    required this.completed,
    required this.brandColor,
    required this.outlineVariantColor,
  });

  final bool completed;
  final Color brandColor;
  final Color outlineVariantColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 2,
      color: completed ? brandColor : outlineVariantColor,
    );
  }
}
