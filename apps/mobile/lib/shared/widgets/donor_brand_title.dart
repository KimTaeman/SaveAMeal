import 'package:flutter/material.dart';

/// The "logo + SaveAMeal" title row used in donor AppBars and the
/// dashboard header. Use with [AppBar(titleSpacing: 0)] so the logo
/// sits flush against the leading back/hamburger button.
class DonorBrandTitle extends StatelessWidget {
  const DonorBrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', height: 28),
        const SizedBox(width: 6),
        Text(
          'SaveAMeal',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
