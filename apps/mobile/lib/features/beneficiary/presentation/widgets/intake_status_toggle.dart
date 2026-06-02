import 'package:flutter/material.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';

class IntakeStatusToggle extends StatelessWidget {
  const IntakeStatusToggle({
    super.key,
    required this.availability,
    required this.onChanged,
  });

  final BeneficiaryIntakeAvailability availability;
  final ValueChanged<BeneficiaryIntakeAvailability> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleSegment(
            label: 'Accepting',
            isActive: availability == BeneficiaryIntakeAvailability.accepting,
            onTap: () => onChanged(BeneficiaryIntakeAvailability.accepting),
          ),
          _ToggleSegment(
            label: 'Full / Busy',
            isActive: availability == BeneficiaryIntakeAvailability.fullBusy,
            onTap: () => onChanged(BeneficiaryIntakeAvailability.fullBusy),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
